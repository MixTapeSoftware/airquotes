import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["fileInput"];

  connect() {
    this.dropZone = this.element;
  }

  dragOver(event) {
    event.preventDefault();
    this.dropZone.classList.add("border-blue-500");
  }

  dragLeave(event) {
    event.preventDefault();
    this.dropZone.classList.remove("border-blue-500");
  }

  drop(event) {
    event.preventDefault();
    this.dropZone.classList.remove("border-blue-500");
    const files = event.dataTransfer.files;
    this.handleFiles(files);
  }

  handleFiles(event) {
    const files = event.target?.files || event;
    if (!files.length) return;
    Array.from(files).forEach((file) => {
      this.uploadFile(file);
    });
  }

  async uploadFile(file) {
    const formData = new FormData();
    formData.append("quote[document]", file);

    try {
      const response = await fetch("/quotes/upload", {
        method: "POST",
        body: formData,
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
            .content,
        },
      });

      if (response.ok) {
        const data = await response.json();
        this.addFileToList(data);
      } else {
        console.error("Upload failed:", response.statusText);
      }
    } catch (error) {
      console.error("Upload error:", error);
    }
  }

  async addFileToList(data) {
    const quotesList = document.getElementById("quotes-list");
    const compareForm = document.getElementById("compare-form");
    const selectedCount = document.getElementById("selected-count");

    try {
      const response = await fetch(`/quotes/${data.id}/quote_list_row`, {
        headers: {
          Accept: "text/html",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
      });

      if (response.ok) {
        const html = await response.text();
        const tempDiv = document.createElement("div");
        tempDiv.innerHTML = html;
        const fileElement = tempDiv.firstElementChild;
        quotesList.prepend(fileElement);
        
        // Show compare form and selection count if this is the first quote
        if (quotesList.children.length === 1) {
          compareForm.classList.remove('hidden');
          compareForm.classList.add('block');
          selectedCount.classList.remove('hidden');
        }
        
        // Update the selection count after adding new quote
        const event = new Event('change');
        document.querySelector('.quote-checkbox').dispatchEvent(event);
      } else {
        console.error("Failed to fetch quote list row HTML");
      }
    } catch (error) {
      console.error("Error fetching quote list row HTML:", error);
    }
  }

  deleteQuote(event) {
    event.preventDefault();
    const button = event.currentTarget;
    const quoteId = button.dataset.quoteId;

    if (!confirm("Are you sure?")) return;

    // Get the associated form using the form attribute
    const formId = button.getAttribute("form");
    const form = document.getElementById(formId);

    if (form) {
      form.submit();
    } else {
      // Fallback to fetch if form isn't found
      fetch(`/quotes/${quoteId}`, {
        method: "DELETE",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
            .content,
          Accept: "application/json",
        },
      }).then((response) => {
        if (response.ok) {
          // Remove the quote row from the DOM
          const row = document.getElementById(`quote-${quoteId}`);
          if (row) row.remove();
          
          // Hide compare form and selection count if this was the last quote
          const quotesList = document.getElementById("quotes-list");
          if (quotesList.children.length === 0) {
            const compareForm = document.getElementById("compare-form");
            const selectedCount = document.getElementById("selected-count");
            compareForm.classList.remove('block');
            compareForm.classList.add('hidden');
            selectedCount.classList.add('hidden');
          }
        } else {
          alert("Failed to delete quote.");
        }
      });
    }
  }
}
