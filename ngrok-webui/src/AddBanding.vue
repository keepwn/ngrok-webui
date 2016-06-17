<template>

    <div id="bandingform">
      <label :class="{'class-success': !isError, 'class-error': isError}" :hidden=" msg=='' "><i>{{ msg }}</i></label>
      <mdl-textfield floating-label="Tunnel Name" :value.sync="example.name"></mdl-textfield>
      <div class="row">
        <mdl-textfield floating-label="Local Addr" :value.sync="example.localaddr"></mdl-textfield>
        <mdl-select label="Proto" id="proto-select" :value.sync="example.proto" :options="protoArray"></mdl-select>
      </div>
      <div class="row">
        <mdl-switch :checked.sync="setAuth" :hidden="!canSetAuth">Auth</mdl-switch>
        <mdl-textfield label="user:password" :value.sync="example.auth" :hidden="!canSetAuth || !setAuth"></mdl-textfield>
      </div>
      <div class="row">
        <mdl-switch :checked.sync="setRandomPort" :hidden="!canSetRandomPort">Random Port</mdl-switch>
        <mdl-textfield floating-label="Remote Port" :value.sync="example.remoteport" :hidden="!canSetRandomPort || setRandomPort"></mdl-textfield>
      </div>
      <div class="row">
        <mdl-switch :checked.sync="setHostname" :hidden="!canSetHostname">Hostname</mdl-switch>
        <mdl-textfield label="my.domain.com" :value.sync="example.hostname" :hidden="!canSetHostname || !setHostname"></mdl-textfield>
      </div>
      <mdl-button @click="create" v-if="!updateMode" v-mdl-ripple-effect raised colored>Create Me</mdl-button>
      <mdl-button @click="update" v-else v-mdl-ripple-effect raised colored>Update Me</mdl-button>
    </div>
</template>

<script>
export default {
  props: {
    updateMode: {
        type: Boolean,
        default: function () {
            return false;
        }
    },
    example: {
        type: Object,
        coerce: function (val) {
          if ( val && typeof(val)=="object"
                   && Object.getOwnPropertyNames(val).length>0 ){
            return val;
          }else{
            return {
                  name: "default",
                  localaddr: "127.0.0.1:8080",
                  remoteport: "10000",
                  random: false,
                  auth: "user:password",
                  hostname: "",
                  proto: "http",
            };
          }
        }
    }
  },
  data () {
    return {
      protoArray: [
        {name:'HTTP', value:'http' },
        {name:'HTTPS', value:'https'},
        {name:'TCP', value:'tcp'}
      ],
      setAuth: this.example.auth ? true : false,
      setRandomPort: true,
      setHostname: this.example.hostname ? true : false,
      isError: false,
      msg: ""
    }
  },
  computed: {
    canSetAuth () {
      return this.example.proto == 'http'|| this.example.proto == 'https' ? true : false;
    },
    canSetRandomPort () {
      return this.example.proto == 'tcp' ? true : false;
    },
    canSetHostname () {
      return this.example.proto == 'http'|| this.example.proto == 'https' ? true : false;
    },
  },
  methods: {
    getTunnelDict () {
      var tunnel_dict = {};

      if (this.updateMode){
        tunnel_dict['id'] = this.example.id;
      }
      tunnel_dict['name'] = this.example.name;
      tunnel_dict['localaddr'] = this.example.localaddr;
      tunnel_dict['proto'] = this.example.proto;

      if (this.canSetAuth && this.setAuth){
        tunnel_dict['auth'] = this.example.auth;
      }
      if (this.canSetRandomPort && !this.setRandomPort){
        tunnel_dict['remoteport'] = this.example.remoteport;
      }
      if (this.canSetHostname && this.setHostname){
        tunnel_dict['hostname'] = this.example.hostname;
      }
      console.log(tunnel_dict);
      return tunnel_dict;
    },
    create () {
      var tunnel_dict = this.getTunnelDict();
      this.$http
        .post('service/api/tunnels', tunnel_dict)
        .then(function (response) {
          console.log(response.data);
          var data = response.data;
          if (data.error){
            this.msg = data.msg;
            this.isError = true;
          }else{
            this.msg = "Create Success!";
            this.isError = false;
          }
        });
    },
    update () {
      var tunnel_dict = this.getTunnelDict();
      var id = tunnel_dict['id'];

      //this.$parent.close();
    }
  }
}
</script>

<style>
.class-success {
  color: green
}
.class-error {
  color: red
}
</style>