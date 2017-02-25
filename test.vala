enum State {
    START,
    IDLE,
    END,
    ERROR,
    WAIT;

    public bool is_idle () {
        return this == IDLE;
    }

    public bool is_end () {
        return this == END;
    }

    public bool is_wait () {
        return this == WAIT;
    }

    public bool is_error () {
        return this == ERROR;
    }

    public string to_string() {
        switch (this) {
            case IDLE:
                return "IDLE";

            case END:
                return "END";

            case WAIT:
                return "WAIT";

            case ERROR:
                return "ERROR";

            default:
                assert_not_reached();
        }
    }
}

State state = State.START;

void change_state(Message message, State newState) {

  stdout.printf ("State changed from %d to %d.\n", state, newState);

  state = newState;

  switch (state) {
    case State.START:{
      stdout.printf("[CHANGE STATE] START \n");
      break;
    }

      case State.IDLE:{
        message.send();
        break;
      }

      case State.END:{
        stdout.printf("[CHANGE STATE] END \n");
        break;
      }

      case State.WAIT: {
        stdout.printf("[CHANGE STATE] WAIT \n");
        break;
      }

      case State.ERROR:{
        stdout.printf("[CHANGE STATE] ERROR \n");
        break;
      }

      default: {
        assert_not_reached();
      }
  }
}

class Test {
  string str;
  public Test(){
    str = @"Hello from test";
  }

  public string getStr(){
    return str;
  }

  public void setString(string str){
    this.str = str;
  }
}

class Message : Object {
  public static const int REPEAT_MESSAGE_MAX = 5;
  SocketConnection conn;
  string message;
  string host;
  int cnt_repeat = 0;

  static construct {
    stdout.printf ("Static Message constructor invoked.\n");
  }

 public Message.default(){
   base();
 }

  public Message(SocketConnection conn, string host){
    this.conn = conn;
    this.host = host;
  }

  public void setMessage(string message) {
    this.message = message;
  }

  public string getMessage(){
    return message;
  }

  public void setHost(string host) {
    this.host = host;
  }

  public string getHost() {
    return host;
  }

  public void send(){
    conn.output_stream.write (message.data);
    DataInputStream response = new DataInputStream (conn.input_stream);
    string status_line = response.read_line (null).strip ();
    handle(status_line);
  }

  private void handle(string status_line) {
    stdout.printf ("[HANDLE] Received status line: %s\n", status_line);
    cnt_repeat = cnt_repeat + 1;
    if (cnt_repeat < REPEAT_MESSAGE_MAX) {
      change_state(this, State.IDLE);
    } else {
      change_state(this, State.END);
    }
  }
}

class HttpMessage : Message {
  public HttpMessage(SocketConnection conn, string host) {
    base(conn, host);
    setMessage(@"GET / HTTP/1.1\r\nHost: %s\r\n\r\n".printf (getHost()));
  }
}

public static void http_get_sync (string host) {
	try {
		Resolver resolver = Resolver.get_default ();
		List<InetAddress> addresses = resolver.lookup_by_name (host, null);
		InetAddress address = addresses.nth_data (0);
		SocketClient client = new SocketClient ();
		SocketConnection conn = client.connect (new InetSocketAddress (address, 80));
    Message google = new HttpMessage(conn, host);
    google.send();
	} catch (Error e) {
		stdout.printf ("Error: %s\n", e.message);
	}
}

void main(){
  Message startMessage = new Message.default();
  change_state(startMessage, State.START);
  Test test = new Test ();
  stdout.printf ("%s\n", test.getStr ());
  http_get_sync ("www.google.at");
}

public class JSONParser {
  string jsonString = "{\"MAGIC\":\"RM_475A4AA5\", \"SUUID\":\"0\", \"DUUID\":\"0\", \"DEVICETYPE\":\"1\", \"operation\":{\"type\":\"request-response\", \"name\":\"probe\"}, \"parameter\":{\"version\":\"1.0.4\"}, \"response\":{\"return\":\"0\",\"version\":\"1.0.4\",\"devicename\":\"600D1234\",\"alivenet\":\"0\",\"webport\":\"80\",\"mediaport\":\"80\",\"mobileport\":\"0\",\"ethernet\":{\"ipmode\":\"1\",\"address\":\"10.0.0.4\",\"netmask\":\"255.255.255.255\", \"gateway\":\"10.0.0.1\",\"primarydns\":\"8.8.8.8\", \"alternatdns\":\"8.8.8.9\", \"MAC\":\"123456789\"},\"WIFI\":{}}}";
  Object obj;

  public void parse() {
    var parser = new Json.Parser ();
    parser.load_from_data (jsonString);
    var root_object = parser.get_root ().get_object ();
    var operation = root_object.get_object_member ("operation");
    var parameter = root_object.get_object_member ("parameter");
    var response = root_object.get_object_member ("response");
    string magic = root_object.get_string_member ("MAGIC");
    int64 suuid = response.get_int_member ("SUUID");
    int64 duuid = response.get_int_member ("DUUID");
    int64 devicetype = response.get_int_member ("DEVICETYPE");
    stdout.printf ("%s\n", magic);
  }

}
