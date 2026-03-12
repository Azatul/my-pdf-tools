defmodule MyPdfToolsWeb.ConvertLive do
  use MyPdfToolsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Convert & Transform")
     |> assign(:wide, true)
     |> assign(:action, "compress")
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
              <.icon name="hero-arrow-path" class="size-6" />
            </div>
            <div>
              <h1 class="text-2xl font-bold text-base-content">Convert & Transform</h1>
              <p class="text-sm text-base-content/70">Compress, add a watermark, or convert to images.</p>
            </div>
          </div>

          <form id="convert-form" phx-submit="transform" class="space-y-6">
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
              <label class="block text-sm font-medium text-base-content mb-2">Action</label>
              <div class="flex flex-wrap gap-3">
                <label class="flex cursor-pointer items-center gap-2 rounded-lg border border-base-300 bg-base-100 px-4 py-3 transition has-[:checked]:border-primary has-[:checked]:bg-primary/10">
                  <input type="radio" name="action" value="compress" checked={@action == "compress"} class="radio radio-primary radio-sm" phx-click="set_action" phx-value-action="compress" />
                  <span class="text-sm font-medium">Compress</span>
                </label>
                <label class="flex cursor-pointer items-center gap-2 rounded-lg border border-base-300 bg-base-100 px-4 py-3 transition has-[:checked]:border-primary has-[:checked]:bg-primary/10">
                  <input type="radio" name="action" value="watermark" checked={@action == "watermark"} class="radio radio-primary radio-sm" phx-click="set_action" phx-value-action="watermark" />
                  <span class="text-sm font-medium">Add watermark</span>
                </label>
                <label class="flex cursor-pointer items-center gap-2 rounded-lg border border-base-300 bg-base-100 px-4 py-3 transition has-[:checked]:border-primary has-[:checked]:bg-primary/10">
                  <input type="radio" name="action" value="to_images" checked={@action == "to_images"} class="radio radio-primary radio-sm" phx-click="set_action" phx-value-action="to_images" />
                  <span class="text-sm font-medium">PDF to images</span>
                </label>
              </div>
            </div>

            <div class="flex gap-3 pt-2">
              <button
                type="submit"
                class="inline-flex items-center gap-2 rounded-lg bg-primary px-5 py-2.5 text-sm font-semibold text-primary-content shadow transition hover:opacity-90 disabled:opacity-50"
                disabled={Enum.empty?(@uploads.pdf.entries)}
              >
                <.icon name="hero-arrow-path" class="size-5" />
                Apply
              </button>
            </div>
          </form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("transform", %{"action" => action}, socket) do
    if Enum.empty?(socket.assigns.uploads.pdf.entries) do
      {:noreply, put_flash(socket, :error, "Upload a PDF first.")}
    else
      result =
        consume_uploaded_entries(socket, :pdf, fn %{path: path}, _entry ->
          {:ok, path}
        end)

      case result do
        [] ->
          {:noreply, put_flash(socket, :error, "Upload failed. Try again.")}

        [path | _] ->
          out = transform_pdf(path, action)
          if out do
            {:noreply,
             socket
             |> put_flash(:info, "Done.")
             |> push_navigate(to: "/")}
          else
            {:noreply,
             put_flash(socket, :error, "Transform not available yet. Wire ConvertLive to your PDF tools.")}
          end
      end
    end
  end

  def handle_event("remove", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :pdf, ref)}
  end

  def handle_event("set_action", %{"action" => action}, socket) do
    {:noreply, assign(socket, :action, action)}
  end

  defp transform_pdf(_path, _action) do
    # Stub: compress (qpdf), watermark (pdftk/ghostscript), to_images (pdftoppm/ImageMagick)
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
