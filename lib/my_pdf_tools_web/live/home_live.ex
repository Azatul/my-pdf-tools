defmodule MyPdfToolsWeb.HomeLive do
  use MyPdfToolsWeb, :live_view

  @features [
    %{
      icon: "hero-document-duplicate",
      title: "Merge PDFs",
      description: "Combine multiple PDF files into a single document. Reorder pages and keep everything in one place."
    },
    %{
      icon: "hero-scissors",
      title: "Split & Extract",
      description: "Split PDFs by page ranges or extract specific pages. Get exactly the content you need."
    },
    %{
      icon: "hero-arrow-path",
      title: "Convert & Transform",
      description: "Convert to and from PDF, compress files, and apply watermarks. Full control over your documents."
    },
    %{
      icon: "hero-shield-check",
      title: "Secure & Private",
      description: "Your files are processed securely. No storage, no tracking—just the tools you need."
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "My PDF Tools — PDF merge, split, convert")
     |> assign(:wide, true)
     |> assign(:features, @features)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} wide={@wide}>
      <div class="min-h-[80vh]">
        <%!-- Hero --%>
        <section class="text-center py-16 sm:py-24 lg:py-32">
          <p class="text-sm font-medium tracking-wide text-primary uppercase">
            PDF tools for professionals
          </p>
          <h1 class="mt-4 text-4xl font-bold tracking-tight text-base-content sm:text-5xl lg:text-6xl">
            Do more with your
            <span class="block text-primary">documents</span>
          </h1>
          <p class="mx-auto mt-6 max-w-2xl text-lg text-base-content/70">
            Merge, split, convert, and manage PDFs with a clean, fast interface. No sign-up required—just upload and go.
          </p>
          <div class="mt-10 flex flex-col items-center justify-center gap-4 sm:flex-row">
            <.link
              navigate="#features"
              class="inline-flex items-center gap-2 rounded-lg bg-primary px-6 py-3 text-sm font-semibold text-primary-content shadow-sm transition hover:opacity-90 focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2"
            >
              See what you can do
              <.icon name="hero-arrow-down" class="size-4" />
            </.link>
          </div>
        </section>

        <%!-- Features grid --%>
        <section id="features" class="py-16 sm:py-24 border-t border-base-300">
          <div class="mx-auto max-w-5xl">
            <h2 class="text-center text-2xl font-bold text-base-content sm:text-3xl">
              Everything you need for PDFs
            </h2>
            <p class="mx-auto mt-3 max-w-2xl text-center text-base-content/70">
              Simple, reliable tools that work in your browser. No desktop app, no subscriptions.
            </p>
            <ul class="mt-16 grid gap-8 sm:grid-cols-2 lg:grid-cols-4">
              <li :for={feature <- @features} class="group">
                <div class="rounded-xl border border-base-300 bg-base-200/50 p-6 transition hover:border-primary/30 hover:shadow-md">
                  <div class="flex size-12 items-center justify-center rounded-lg bg-primary/10 text-primary transition group-hover:bg-primary/20">
                    <.icon name={feature.icon} class="size-6" />
                  </div>
                  <h3 class="mt-4 font-semibold text-base-content">{feature.title}</h3>
                  <p class="mt-2 text-sm text-base-content/70">{feature.description}</p>
                </div>
              </li>
            </ul>
          </div>
        </section>

        <%!-- CTA --%>
        <section class="py-16 sm:py-24">
          <div class="mx-auto max-w-3xl text-center">
            <h2 class="text-2xl font-bold text-base-content sm:text-3xl">
              Ready to simplify your PDF workflow?
            </h2>
            <p class="mt-3 text-base-content/70">
              More tools are on the way. Stay tuned for merge, split, and convert—all in one place.
            </p>
          </div>
        </section>
      </div>
    </Layouts.app>
    """
  end
end
