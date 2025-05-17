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

  addFileToList(data) {
    const uploadedFiles = document.getElementById("uploaded-files");
    const fileElement = document.createElement("div");
    fileElement.className =
      "flex items-center justify-between p-3 bg-gray-700 rounded-lg";
    fileElement.innerHTML = `
      <div class="flex items-center space-x-3">
        <svg class="h-6 w-6 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
        </svg>
        <span class="text-sm text-gray-200">${data.filename}</span>
      </div>
      <span class="text-xs text-gray-400">${new Date().toLocaleDateString()}</span>
    `;
    uploadedFiles.prepend(fileElement);
  }
}
