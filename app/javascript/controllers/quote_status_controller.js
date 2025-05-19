import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    quoteId: String,
    pollInterval: { type: Number, default: 2000 } // Poll every 2 seconds
  }

  connect() {
    if (this.hasQuoteIdValue) {
      this.startPolling()
    }
  }

  disconnect() {
    this.stopPolling()
  }

  startPolling() {
    this.pollTimer = setInterval(() => {
      this.checkStatus()
    }, this.pollIntervalValue)
  }

  stopPolling() {
    if (this.pollTimer) {
      clearInterval(this.pollTimer)
      this.pollTimer = null
    }
  }

  async checkStatus() {
    try {
      const response = await fetch(`/quotes/${this.quoteIdValue}/status`)
      const data = await response.json()

      if (data.processed) {
        this.stopPolling()
        this.element.classList.add('hidden')

        // If we're in the compare view, refresh the page to show the new data
        if (window.location.pathname.includes('/compare')) {
          window.location.reload()
        } else {
          // Otherwise, refresh just the quote row
          const quoteRow = document.querySelector(`[data-quote-id="${this.quoteIdValue}"]`)
          if (quoteRow) {
            const response = await fetch(`/quotes/${this.quoteIdValue}/quote_list_row`)
            const html = await response.text()
            quoteRow.outerHTML = html
          }
        }
      }
    } catch (error) {
      console.error('Error checking quote status:', error)
    }
  }
} 