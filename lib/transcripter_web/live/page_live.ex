defmodule TranscripterWeb.PageLive do
  use TranscripterWeb, :live_view


  def mount(_params, _session, socket) do
   socket = socket |> assign(:uploaded_file, []) |> allow_upload(:audio, accept: ["audio/mpeg", "audio/wav"], max_entries: 1)
   {:ok, assign(socket, form: to_form(%{}))}
  end

 # def mount(_params, _session, socket) do
  #  socket =
   #   socket
   #   |> assign(:uploaded_files, [])
    #  |> allow_upload(:audio, accept: ~w(audio/mpeg audio/wav), max_entries: 1)

   # {:ok, socket}
  #end

  #<.live_file_input upload = {@form[:audio]}/>

  def render(assigns) do
    ~H"""
     <.simple_form for = {@form} phx-submit = "save_audio">
     <.live_file_input upload={@uploads.audio} />
     <.button type = "upload">Audio Upload</.button>
     </.simple_form>
    """
  end

  #def render(assigns) do
   # ~H"""
   # <div>
   #   <h2>Upload an Audio File</h2>
    #  <%= f = form_for :upload, "#", phx_submit: :save_audio, multipart: true %>
     #   <%= live_file_input f, :audio %>
      #  <button type="submit">Upload Audio</button>
     # </form>
   # </div>
  #  """
 # end

  def handle_event("upload", _params, socket) do
    {:noreply, socket}
  end

  #def handle_event("save_audio", %{"upload_file" => the_uploaded_file}, socket) do
   # {:noreply, socket}
  #end

end
