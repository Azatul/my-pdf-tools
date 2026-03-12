defmodule MyPdfToolsWeb.SplitLive do
  use MyPdfToolsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Split & Extract")
     |> assign(:wide, true)
     |> assign(:page_ranges, "")
     |> allow_upload(:pdf,
       accept: ~w(.pdf),
       max_entries: 1,
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
              <.icon name="hero-scissors" class="size-6" />
            </div>
            <div>
              <h1 class="text-2xl font-bold text-base-content">Split & Extract</h1>
              <p class="text-sm text-base-content/70">Extract pages by range (e.g. 1-3, 5, 7-9) or split every N pages.</p>
            </div>
          </div>

          <form id="split-form" phx-submit="extract" class="space-y-6">
            <div>
              <label class="block text-sm font-medium text-base-content mb-2">PDF file</label>
              <div
                class="flex flex-col items-center justify-center rounded-lg border-2 border-dashed border-base-300 bg-base-100 p-8 transition hover:border-primary/50"
                phx-drop-target={@uploads.pdf.ref}
              >
                <.live_file_input upload={@uploads.pdf} class="cursor-pointer" />
                <p class="mt-2 text-sm text-base-content/60">or drag and drop a PDF here</p>
              </div>
              <div :for={entry <- @uploads.pdf.entries} class="mt-2 flex items-center gap-2 text-sm">
                <.icon name="hero-document" class="size-4 text-primary" />
                <span>{entry.client_name}</span>
                <button
                  type="button"
                  phx-click="remove"
                  phx-value-ref={entry.ref}
                  class="text-base-content/50 hover:text-error"
                  aria-label="Remove"
                >
                  <.icon name="hero-x-mark" class="size-4" />
                </button>
              </div>
              <p :for={err <- collect_upload_errors(@uploads.pdf)} class="mt-2 text-sm text-error">
                {upload_error_to_string(err)}
              </p>
            </div>

            <div>
              <label for="page-ranges" class="block text-sm font-medium text-base-content mb-2">Page ranges</label>
              <input
                type="text"
                name="page_ranges"
                id="page-ranges"
                value={@page_ranges}
                phx-change="update_page_ranges"
                placeholder="e.g. 1-3, 5, 7-10 or leave empty for all"
                class="input input-bordered w-full"
              />
              <p class="mt-1 text-xs text-base-content/50">Comma-separated: single pages (5) or ranges (1-4).</p>
            </div>

            <div class="flex gap-3 pt-2">
              <button
                type="submit"
                class="inline-flex items-center gap-2 rounded-lg bg-primary px-5 py-2.5 text-sm font-semibold text-primary-content shadow transition hover:opacity-90 disabled:opacity-50"
                disabled={Enum.empty?(@uploads.pdf.entries)}
              >
                <.icon name="hero-scissors" class="size-5" />
                Extract pages
              </button>
            </div>
          </form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("extract", params, socket) do
    page_ranges = Map.get(params, "page_ranges", "") |> String.trim()

    if Enum.empty?(socket.assigns.uploads.pdf.entries) do
      {:noreply, put_flash(socket, :error, "Upload a PDF first.")}
    else
      result =
        consume_uploaded_entries(socket, :pdf, fn %{path: path}, entry ->
          {:ok, %{path: path, name: entry.client_name}}
        end)

      case result do
        [] ->
          {:noreply, put_flash(socket, :error, "Upload failed. Try again.")}

        [%{path: path} | _] ->
          out_path = extract_pages(path, page_ranges)
          if out_path do
            {:noreply,
             socket
             |> put_flash(:info, "Pages extracted.")
             |> push_navigate(to: "/")}
          else
            {:noreply,
             put_flash(socket, :error, "Extract not available yet. Wire SplitLive to qpdf/pdftk.")}
          end
      end
    end
  end

  def handle_event("remove", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :pdf, ref)}
  end

  def handle_event("update_page_ranges", %{"page_ranges" => page_ranges}, socket) do
    {:noreply, assign(socket, :page_ranges, page_ranges)}
  end

  defp extract_pages(_path, _page_ranges) do
    # Stub: use qpdf --pages in.pdf 1-3,5,7 -- out.pdf
    nil
  end

  defp collect_upload_errors(upload) do
    Enum.filter(upload.entries, &(&1.errors != []))
    |> Enum.flat_map(& &1.errors)
  end

  defp upload_error_to_string(:too_many_files), do: "Only one file allowed"
  defp upload_error_to_string(:not_accepted), do: "Only PDF files are accepted"
  defp upload_error_to_string({:too_large, _}), do: "File is too large"
  defp upload_error_to_string(other), do: inspect(other)
end
