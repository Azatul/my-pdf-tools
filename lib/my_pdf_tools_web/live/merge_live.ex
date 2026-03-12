defmodule MyPdfToolsWeb.MergeLive do
  use MyPdfToolsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Merge PDFs")
     |> assign(:wide, true)
     |> allow_upload(:pdfs,
       accept: ~w(.pdf),
       max_entries: 20,
       max_file_size: 50_000_000,
       auto_upload: true
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} wide={@wide}>
      <div class="max-w-3xl mx-auto py-8">
        <.link navigate="/#features" class="inline-flex items-center gap-2 text-sm text-base-content/70 hover:text-base-content mb-8">
          <.icon name="hero-arrow-left" class="size-4" />
          Back to home
        </.link>

        <div class="rounded-xl border border-base-300 bg-base-200/50 p-6 sm:p-8">
          <div class="flex items-center gap-3 mb-6">
            <div class="flex size-12 items-center justify-center rounded-lg bg-primary/10 text-primary">
              <.icon name="hero-document-duplicate" class="size-6" />
            </div>
            <div>
              <h1 class="text-2xl font-bold text-base-content">Merge PDFs</h1>
              <p class="text-sm text-base-content/70">Combine multiple PDFs into one. Reorder with the arrows.</p>
            </div>
          </div>

          <form id="merge-form" phx-submit="merge" class="space-y-6">
            <div>
              <label class="block text-sm font-medium text-base-content mb-2">Select PDF files</label>
              <div
                class="flex flex-col items-center justify-center rounded-lg border-2 border-dashed border-base-300 bg-base-100 p-8 transition hover:border-primary/50"
                phx-drop-target={@uploads.pdfs.ref}
              >
                <.live_file_input upload={@uploads.pdfs} class="cursor-pointer" />
                <p class="mt-2 text-sm text-base-content/60">or drag and drop PDFs here</p>
                <p class="text-xs text-base-content/50 mt-1">Up to 20 files, 50 MB each</p>
              </div>
              <p :for={err <- collect_upload_errors(@uploads.pdfs)} class="mt-2 text-sm text-error">
                {upload_error_to_string(err)}
              </p>
            </div>

            <div :if={Enum.any?(@uploads.pdfs.entries)} class="space-y-3">
              <label class="block text-sm font-medium text-base-content">Order (top = first in merged PDF)</label>
              <ul id="merge-file-list" class="space-y-2">
                <li
                  :for={entry <- @uploads.pdfs.entries}
                  class="flex items-center gap-3 rounded-lg border border-base-300 bg-base-100 px-4 py-3"
                >
                  <.icon name="hero-bars-3-bottom-left" class="size-5 text-base-content/50 shrink-0" />
                  <span class="flex-1 truncate text-sm font-medium">{entry.client_name}</span>
                  <span class="text-xs text-base-content/50">{entry.client_size}</span>
                  <button
                    type="button"
                    phx-click="remove"
                    phx-value-ref={entry.ref}
                    class="text-base-content/50 hover:text-error transition"
                    aria-label="Remove"
                  >
                    <.icon name="hero-x-mark" class="size-5" />
                  </button>
                </li>
              </ul>
            </div>

            <div class="flex gap-3 pt-2">
              <button
                type="submit"
                class="inline-flex items-center gap-2 rounded-lg bg-primary px-5 py-2.5 text-sm font-semibold text-primary-content shadow transition hover:opacity-90 disabled:opacity-50"
                disabled={Enum.empty?(@uploads.pdfs.entries)}
              >
                <.icon name="hero-document-duplicate" class="size-5" />
                Merge PDFs
              </button>
            </div>
          </form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("merge", _params, socket) do
    if Enum.empty?(socket.assigns.uploads.pdfs.entries) do
      {:noreply, put_flash(socket, :error, "Add at least one PDF file.")}
    else
      result =
        consume_uploaded_entries(socket, :pdfs, fn %{path: path}, entry ->
          {:ok, %{path: path, name: entry.client_name}}
        end)

      case result do
        [] ->
          {:noreply, put_flash(socket, :error, "Upload failed. Try again.")}

        paths ->
          # TODO: call PDF merge logic (e.g. qpdf or pdftk) with paths in order
          merged_path = merge_pdfs(Enum.map(paths, & &1.path))
          if merged_path do
            {:noreply,
             socket
             |> put_flash(:info, "PDFs merged successfully.")
             |> push_navigate(to: "/")}
          else
            {:noreply,
             put_flash(socket, :error, "Merge not available yet. Install qpdf or pdftk and wire MergeLive to it.")}
          end
      end
    end
  end

  def handle_event("remove", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :pdfs, ref)}
  end

  defp merge_pdfs(_paths) do
    # Stub: implement with System.cmd("qpdf", ["--empty", "--pages", path1, path2, ..., "--", "out.pdf"])
    # or pdftk path1 path2 ... cat output out.pdf
    nil
  end

  defp collect_upload_errors(upload) do
    Enum.filter(upload.entries, &(&1.errors != []))
    |> Enum.flat_map(& &1.errors)
  end

  defp upload_error_to_string(:too_many_files), do: "Too many files"
  defp upload_error_to_string(:not_accepted), do: "Only PDF files are accepted"
  defp upload_error_to_string({:too_large, _}), do: "File is too large"
  defp upload_error_to_string(other), do: inspect(other)
end
