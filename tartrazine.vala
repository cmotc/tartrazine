using ToxCore;
using Environment;

namespace Tartrazine {
        public class RobotPoison : Object {
            /**Application Variables*/
                private string APP_NAME = ""; /** This is the name of the
                        application that is using Tox as a way of discovering
                        the server*/
                private string HOST_NAME = ""; /**This is the Host's desired
                        nickname for the application server*/
                private string GROUP_NAME = ""; /**This is the name of a group
                        operated by the host*/
                private int GROUP_NUMBER;
                private List<List<string>> MessagesLog = new List<List<string>>();
            /**Main loop*/
                private MainLoop loop = new MainLoop ();
            /**Base Settings Variables*/
                private int HIGH_VOLUME = 32; /**This is the user-configurable
                        high-volume threshold for the application server*/
                private static string TOX_SAVE = "tartrazine.tox"; /**This is
                the filename to use as the save file.*/
                private static string TOX_FOLDER = "tartrazine"; /**This is the
                optional folder to store the save file.*/
                private static List<string> VALID_MOODS = new List<string>(); /**
                        Tartrazine uses a pre-defined list of moods to
                        communicate specific information about the bot*/
                private static List<string> InitMoods(List<string> commands){
                        List<string> tmp = new List<string>();
                        foreach(string i in commands){
                                tmp.append(i);
                        }
                        VALID_MOODS = tmp.copy();
                        return VALID_MOODS.copy();
                } /**This is used to initialize the valid moods*/
                private static List<List<string>> VALID_COMMANDS = new List<List<string>>();
                private static List<List<string>> InitCommands(List<List<string>> commands){
                        List<List<string>> r = new List<List<string>>();
                        foreach(var i in commands.copy()){
                                r.append(i.copy());
                        }
                        VALID_COMMANDS = r.copy();
                        return VALID_COMMANDS.copy();
                } /**This is used to initialize the valid moods*/
            /**Opaque tools*/
                private static string ToxFileName(){
                        string r = (string) get_user_config_dir() + (string) TOX_SAVE;
                        return r;
                } /**This initializes the file name and if necessary, will
                create the folder specified in the constructor*/
                protected class Tools {
                        public static uint8[] hex2bin (string s) {
                                uint8[] buf = new uint8[s.length / 2];
                                for (int i = 0; i < buf.length; ++i) {
                                        int b = 0;
                                        s.substring (2*i, 2).scanf ("%02x", ref b);
                                        buf[i] = (uint8)b;
                                }
                                return buf;
                        }/**Convert hex to bin*/
                        public static string bin2hex (uint8[] bin)
                                requires (bin.length != 0) {
                                StringBuilder b = new StringBuilder ();
                                for (int i = 0; i < bin.length; ++i) {
                                        b.append ("%02X".printf (bin[i]));
                                }
                                return b.str;
                        }/**Convert bin to hex*/
                        public static string bin2nullterm (uint8[] data) {
                                //TODO optimize this
                                uint8[] buf = new uint8[data.length + 1];
                                Memory.copy (buf, data, data.length);
                                string sbuf = (string)buf;

                                if (sbuf.validate ()) {
                                        return sbuf;
                                }
                                // Extract usable parts of the string
                                StringBuilder sb = new StringBuilder ();
                                for (unowned string s = sbuf; s.get_char () != 0; s = s.next_char ()) {
                                        unichar u = s.get_char_validated ();
                                        if (u != (unichar) (-1)) {
                                                sb.append_unichar (u);
                                        } else {
                                                stdout.printf ("Invalid UTF-8 character detected");
                                        }
                                }
                                return sb.str;
                        }/**null-terminate binary file*/
                        public static string arr2str (uint8[] array) {
                                uint8[] name = new uint8[array.length + 1];
                                GLib.Memory.copy (name, array, sizeof(uint8) * name.length);
                                name[array.length] = '\0';
                                return ((string) name).to_string ();
                        }/**convert array to string*/
                }/**This is the Generic Tools necessary to fill in support*/
                class Server : Object {
                        public string owner { get; set; }
                        public string region { get; set; }
                        public string ipv4 { get; set; }
                        public string ipv6 { get; set; }
                        public uint64 port { get; set; }
                        public string pubkey { get; set; }
                } /**This holds information about the server*/
            /**Tox related variables*/
                private Options options = new Options (null);
                private Tox handle;

            /**Likely to be deleted and replaced with a function*/
                private bool connected = false;

            /**Parameterized Constructor*/
                public RobotPoison.WithAppParams(string app, string host, string igroup,
                        string folder, string filename, List<string> moods, List<List<string>> commands){
                        print ("Running Toxcore version %u.%u.%u\n",
                        ToxCore.Version.MAJOR, ToxCore.Version.MINOR, ToxCore.Version.PATCH);
                        VALID_MOODS = InitMoods(moods);
                        VALID_COMMANDS = InitCommands(commands);

                        TOX_SAVE = filename;
                        APP_NAME = app;
                        HOST_NAME = host;
                        GROUP_NAME = igroup;

                        this.SaveSet();

                        this.bootstrap.begin ();

                        this.RegisterCallBacks();
                }

            /**This sets the base settings and instantiates the handle*/
                public void SaveSet(){
                        options.ipv6_enabled = true;
                        options.udp_enabled = true;
                        options.proxy_type = ProxyType.NONE;

                        if (FileUtils.test (this.TOX_SAVE, FileTest.EXISTS)) {
                                FileUtils.get_data (this.TOX_SAVE, out options.savedata_data);
                                this.options.savedata_type = SaveDataType.TOX_SAVE;
                        }

                        this.handle = new Tox (options, null);

                        this.handle.self_set_name (this.APP_NAME.data, null);
                        this.handle.self_set_status_message (this.GetStatus().data, null);

                        uint8[] name = new uint8[this.handle.self_get_name_size ()];
                        this.handle.self_get_name (name);
                        print ("Tox name: %s\n", Tools.bin2nullterm (name));

                        uint8[] toxid = new uint8[ADDRESS_SIZE];
                        this.handle.self_get_address (toxid);
                        print ("ToxID: %s\n", Tools.bin2hex (toxid));
                }
            /**This starts the client bootstrapping from the list from tox.chat*/
                private async void bootstrap (){
                        var sess = new Soup.Session ();
                        var msg = new Soup.Message ("GET", "https://build.tox.chat/job/nodefile_build_linux_x86_64_release/lastSuccessfulBuild/artifact/Nodefile.json");
                        var stream = yield sess.send_async (msg, null);
                        var json = new Json.Parser ();
                        if (yield json.load_from_stream_async (stream, null)) {
                                Server[] servers = {};
                                var array = json.get_root ().get_object ().get_array_member ("servers");
                                array.foreach_element ((arr, index, node) => {
                                        servers += Json.gobject_deserialize (typeof (Server), node) as Server;
                                });
                                while (!this.connected) {
                                        for (int i = 0; i < 4; ++i) { // bootstrap to 4 random nodes
                                                int index = Random.int_range (0, servers.length);
                                                print ("Bootstrapping to %s:%llu by %s\n", servers[index].ipv4, servers[index].port, servers[index].owner);
                                                this.handle.bootstrap (
                                                        servers[index].ipv4,
                                                        (uint16) servers[index].port,
                                                        Tools.hex2bin (servers[index].pubkey),
                                                        null
                                                );
                                        }

                                        // wait 5 seconds without blocking main loop
                                        Timeout.add (5000, () => {
                                                bootstrap.callback ();
                                                return Source.REMOVE;
                                        });
                                        yield;
                                }
                                print ("Done bootstrapping\n");
                        }
                }
            /**This registers the callbacks*/
                private void RegisterCallBacks(){
                        this.handle.callback_self_connection_status ((handle, status) => {
                                if (status != ConnectionStatus.NONE) {
                                        print ("Connected to Tox\n");
                                        this.connected = true;
                                } else {
                                        print ("Disconnected\n");
                                        this.connected = false;
                                }
                        });
                        this.handle.callback_friend_message (this.OnFriendMessage);
                        this.handle.callback_friend_request (this.OnFriendRequest);
                        this.handle.callback_friend_status (this.OnFriendStatus);
                }
            /**This sets up the groups and their callbacks*/
                private void SetupGroups(){
                        this.GROUP_NUMBER = this.handle.add_groupchat ();
                        this.handle.group_set_title (this.GROUP_NUMBER, "Ricin groupchat".data);

                        this.handle.callback_group_message ((self, GROUP_NUMBER, peer_number, message) => {
                        if (this.handle.group_peernumber_is_ours (GROUP_NUMBER, peer_number) == 1) {
                                return;
                        }

                        string message_string = Tools.arr2str (message);
                                debug (@"$peer_number: $message_string");
                        });

                        this.handle.callback_group_action ((self, GROUP_NUMBER, peer_number, action) => {
                                string action_string = Tools.arr2str (action);
                                debug (@"* $peer_number $action_string");
                        });

                        this.handle.callback_group_title ((self, GROUP_NUMBER, peer_number, title) => {
                                this.handle.group_message_send (GROUP_NUMBER, @"$peer_number changed topic to $(Tools.arr2str(title))".data);
                        });
                }
            /***/
                private void OnFriendMessage (Tox handle, uint32 friend_number, MessageType type, uint8[] message) {
                        string temp = (string) message;
                        int index = -1; //DON'T REMOVE THESE. We need index to
                        //be negative at first because we know that's an invalid
                        //value.
                        int c = 0; // This is the count and it will only be used
                        //to set the index if we are sure that a friend already
                        //exists.
                        uint8[] result = new uint8[MAX_NAME_LENGTH];
                        this.handle.friend_get_name (friend_number, result, null);

                        if (temp.has_prefix ("add ")) {
                                var tox_id = temp.splice (0, 4);
                                var _message = "Add me plz ?";
                                //print ("Sending a friend request to %s: \"%s\"\n", tox_id, _message);
                                uint32 friend_num = this.handle.friend_add (Tools.hex2bin (tox_id), _message.data, null);
                                //print ("friend_num == %u\n", friend_num);
                                return;
                        }
                        foreach (var d in VALID_COMMANDS.copy()){
                                if (temp.down() == d.nth_data(0)){
                                        string respond = d.nth_data(1);
                                        this.handle.friend_send_message (friend_number, MessageType.ACTION, respond.data, null);
                                }
                        }
                        foreach (var i in MessagesLog.copy()){
                                if (i.length() > 0){
                                        if ( (string) friend_number == i.nth_data(0) ){
                                                index = c;
                                        }
                                }
                                c++;
                        }

                        if ( index != -1){
                                MessagesLog.nth_data(c).append(temp);
                        }else{
                                List<string> t = new List<string>();
                                t.append((string) friend_number);
                                MessagesLog.append(t.copy());
                        }
                }
            /***/
                private string GetLastMessage(string friend_number){
                        string r = null;
                        foreach (var i in MessagesLog.copy()){
                                if ( friend_number == i.nth_data(0) ){
                                      r = i.nth_data(i.length());
                                }else if ( friend_number == i.nth_data(1) ){
                                        r = i.nth_data(i.length());
                                }
                        }
                        return r;
                }
            /***/
                private void OnFriendRequest (Tox handle, uint8[] public_key, uint8[] message) {
                        public_key.length = PUBLIC_KEY_SIZE; // Fix an issue with Vala.
                        var pkey = Tools.bin2hex (public_key);
                        var message_string = (string) message;

                        this.handle.friend_add_norequest (public_key, null);

                        // Save the friend in the .tox file.
                        this.SaveData();
                }
            /***/
                private string GetFriendRequest(){
                        string r = null;
                        return r;
                }
            /***/
                private void OnFriendStatus (Tox handle, uint32 friend_number, UserStatus status) {
                }
            /***/
                private string GetFriendStatus(){
                        string r = null;
                        return r;
                }
            /***/
                public void FriendSendMessage(uint32 friendNumber, string message){
                }
            /**Get the server status*/
                public string GetStatus(){
                        string r = null;//VALID_MOODS.first();
                        //if (){}
                        return r;
                }
            /***/
                public bool SaveData(){
                        string TOX_PATH = ToxFileName();
                        info ("Saving data to " + TOX_PATH);
                        uint32 size = this.handle.get_savedata_size ();
                        uint8[] buffer = new uint8[size];
                        this.handle.get_savedata (buffer);
                        return FileUtils.set_data (TOX_PATH, buffer);
                }
            /***/
                private List<string> LoadConfig(string path){
                        List<string> r = new List<string>();
                        return r;
                }
            /***/
                private string ToxSave(){
                        string r = "";
                        return r;
                }
            /***/
                public bool Online(){
                        bool r = false;
                        return r;
                }
            /***/
                void ToxLoop() {
                        var interval = this.handle.iteration_interval();
                        Timeout.add (interval, () => {
                                this.handle.iterate();
                                this.ToxLoop();
                                return Source.REMOVE;
                        });
                }
                public static void main(){
                }
        }
}
