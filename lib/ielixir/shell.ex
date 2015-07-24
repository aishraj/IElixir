defmodule IElixir.Shell do
  use GenServer
  require Logger
  alias IElixir.Message
  alias IElixir.IOPub
  alias IElixir.Utils
  alias IElixir.Sandbox

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, [])
  end

  def init(opts) do
    Logger.debug("Shell PID: #{inspect self()}")
    sock = Utils.make_socket(opts, "shell", :router)
    {:ok, {sock, []}}
  end

  def terminate(_reason, {sock, _}) do
    :erlzmq.close(sock)
  end

  def handle_info({:zmq, _, message, flags}, {sock, message_buffer}) do
    case Message.assemble_message(message, flags, message_buffer) do
      {:buffer, buffer} ->
        {:noreply, {sock, buffer}}
      {:msg, message} ->
        process(message.header["msg_type"], message, sock)
        {:noreply, {sock, []}}
    end
  end
  def handle_info(message, state) do
    Logger.warn("Got unexpected message on shell process: #{inspect message}")
    {:noreply, state}
  end

  defp process("kernel_info_request", message, sock) do
    Logger.debug("Received kernel_info_request")
    {:ok, version} = Version.parse(System.version)
    content = %{
      "protocol_version": "5.0",
      "implementation": "ielixir",
      "implementation_version": "1.0",
      "language_info": %{
        "name" => "elixir",
        "version" => inspect(version),
        "mimetype" => "",
        "file_extension" => ".ex",
        "pygments_lexer" => "",
        "codemirror_mode" => "",
        "nbconvert_exporter" => ""
      },
      "banner": "",
      "help_links": [%{
        "text" => "",
        "url" => ""
      }]
    }
    send_message(sock, message, "kernel_info_reply", content)
  end
  defp process("execute_request", message, sock) do
    Logger.debug("Received execute_request: #{inspect message}")
    IOPub.send_status("busy", message)
    IOPub.send_execute_input(message)
    result = Sandbox.execute_code(message.content)
    IOPub.send_stream(message, "hello, world\n")
    IOPub.send_execute_result(message, result)
    IOPub.send_status("idle", message)
    content = %{
      "status": "ok",
      "execution_count": 5,
      "payload": [],
      "user_expressions": %{}
    }
    send_message(sock, message, "execute_reply", content)
  end
  defp process(msg_type, message, _sock) do
    Logger.info("Received message of type: #{msg_type} @ shell socket: #{inspect message}")
  end

  def send_message(sock, message, message_type, content) do
    new_message = %{message |
      "parent_header": message.header,
      "header": %{message.header |
        "msg_type" => message_type
      },
      "content": content
    }
    Utils.send_all(sock, Message.encode(new_message))
  end
end

