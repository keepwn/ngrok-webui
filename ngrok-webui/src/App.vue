<template>
  <div id="app">
    <div class="mdl-grid">
      <div class="mdl-cell mdl-cell--1-col"></div>
      <div class="mdl-cell mdl-cell--10-col">
        <h1>{{ msg }}</h1>
        <div>
          <mdl-dialog title="Tunnel Configure" @close="closeCallback" v-ref:info-message cancellable>
            <add-banding :update-mode="updateMode" :example="example"></add-banding>
          </mdl-dialog>
        </div>

        <div>
          <mdl-dialog title="Tunnel Log" v-ref:tunnel-log>
            <textarea v-model="tunnelLog" cols="55" rows="20" readonly="readonly"></textarea>
          </mdl-dialog>
        </div>

        <div>
          <mdl-button v-mdl-ripple-effect raised colored @click="createone">Create New</mdl-button>
          <mdl-button v-mdl-ripple-effect raised colored v-show="isShowAction" @click="editone">Edit</mdl-button>
          <mdl-button v-mdl-ripple-effect raised colored v-show="isShowAction" @click="deleteone">Delete</mdl-button>
        </div>
        <div class="container">
          <table id="banding-table" class="mdl-data-table mdl-js-data-table mdl-shadow--2dp">
            <thead>
              <th>
                <mdl-checkbox v-mdl-ripple-effect :checked.sync='isCheckedAll' v-on:click="checkedAll"></mdl-checkbox>
              </th>
              <th>Id</th>
              <th>Name</th>
              <th>Local-Addr</th>
              <th>Remote-Addr</th>
              <th>State</th>
              <th>Actions</th>
            </thead>
            <tbody>
              <tr v-for="service in services" id="tr{{ $index }}">
                <td>
                  <!--mdl-checkbox class="mdl-js-ripple-effect mdl-data-table__select mdl-js-ripple-effect--ignore-events"></mdl-checkbox-->
                  <mdl-checkbox v-mdl-ripple-effect :value="service.id" :checked.sync='checkboxes'></mdl-checkbox>
                </td>
                <td>{{ $index }}</td>
                <td>{{ service.name }}</td>
                <td>{{ service.localaddr }}</td>
                <td>{{ service | convertToRemoteAddr }}</td>
                <td>{{ service.state }}</td>
                <td>
                  <mdl-tooltip :for="'start-button-'+$index">start</mdl-tooltip>
                  <mdl-tooltip :for="'stop-button-'+$index">stop</mdl-tooltip>
                  <mdl-tooltip :for="'rebuild-button-'+$index">rebuild</mdl-tooltip>
                  <mdl-tooltip :for="'log-button-'+$index">log</mdl-tooltip>
                  <mdl-button :id="'start-button-'+$index" icon=true @click="start(service.id)" v-show="service.exists && service.state != 'running'">
                    <i class="material-icons">play_arrow</i>
                  </mdl-button>
                  <mdl-button :id="'stop-button-'+$index" icon=true v-on:click="stop(service.id)" v-show="service.exists && service.state == 'running'">
                    <i class="material-icons">stop</i>
                  </mdl-button>
                  <mdl-button :id="'rebuild-button-'+$index" icon=true v-on:click="rebuild(service.id)">
                    <i class="material-icons">replay</i>
                  </mdl-button>
                  <mdl-button :id="'log-button-'+$index" icon=true v-on:click="log(service.id)">
                    <i class="material-icons">description</i>
                  </mdl-button>
                </td>
              </tr>
            </tbody>
          </table>
          <br>
          <span>checkboxes: {{ checkboxes | json }}</span>
        </div>
      </div>
      <div class="mdl-cell mdl-cell--1-col"></div>
    </div>
  </div>
</template>

<script>
import AddBanding from './AddBanding.vue'

export default {
  components: { AddBanding },
  data () {
    return {
      msg: 'Ngrok WebUI',
      //checkedAll: false,
      checkboxes: [],
      updateMode: false,
      example: null,
      services: [
        {
          id: 1,
          name: "serviceA",
          localaddr: "127.0.0.1:8080",
          remoteport: "10000",
          proto: "HTTP"
        }
      ],
      status: {},
      tunnelLog: ''
    }
  },
  computed: {
    isCheckedAll() {
      return this.checkboxes.length == this.services.length;
    },
    isShowAction(){
      return this.checkboxes.length > 0;
    },
  },
  ready () {
    this.list();

    let self = this;
    setInterval(function(){
        self.list();
      }, 5000);
  },
  methods: {
    checkedAll (event) {
      if (event.target.tagName == "INPUT"){
        if (this.isCheckedAll){
          this.checkboxes = []
        }else{
          let checks = [];
          for (var service of this.services) {
            checks.push(service.id);
          }
          this.checkboxes = checks;
        }
      }
    },
    get_status (id) {
      this.$http.get('service/api/tunnels/'+id+'/status').then(function (response) {
          let data = response.data;
          if (data.error){
            return '';
          }else{
            return data.data;
          }
        }, function (response) {
      });
    },
    list () {
      this.$http.get('service/api/tunnels').then(function (response) {
          this.$set('services', response.data.data)
        }, function (response) {
          // error callback
      });
    },
    start (id) {
      console.log('start id: '+id);
      this.$http
        .patch('service/api/tunnels/'+id, {"action":"start"})
        .then(function (response) {
          //console.log(response.data.data);
          this.list();
        });
    },
    stop (id) {
      console.log('stop id: '+id);
      this.$http
        .patch('service/api/tunnels/'+id, {"action":"stop"})
        .then(function (response) {
          this.list();
        });
    },
    rebuild (id) {
      console.log('rebuild id: '+id);
      this.$http
        .patch('service/api/tunnels/'+id, {"action":"rebuild"})
        .then(function (response) {
          this.list();
        });
    },
    log (id) {
      this.$http
        .get('service/api/tunnels/'+id+'/log')
        .then(function (response) {
          let logList = response.data.data;
          this.tunnelLog = logList.join('\n');
          console.log(this.tunnelLog);
          this.$refs.tunnelLog.open();
        });
    },
    createone () {
      this.example = null;
      this.updateMode = false;
      this.$refs.infoMessage.open();
    },
    editone () {
      this.example = null;
      var selected_id = this.checkboxes[0];
      for(var i=0; i<this.services.length; i++) {
          if (selected_id == this.services[i].id){    
              //this.example = this.services[i];
              // deep clone
              this.example = JSON.parse(JSON.stringify( this.services[i] ));
              break;
          }
      }
      this.updateMode = true;
      this.$refs.infoMessage.open();
    },
    deleteone () {
      for(var i=0; i<this.checkboxes.length; i++) {
          let id = this.checkboxes[i];
          console.log('delete id: '+id);
          this.$http
            .delete('service/api/tunnels/'+id)
            .then(function (response) {
              console.log('id: '+id+' deleted');
            });
      }
      this.list();
    },
    closeCallback () {
      this.list();
    }
  },
  filters: {
    reverse (value) {
      return value.split('').reverse().join('');
    },
    convertToRemoteAddr (tunnel) {
      if (tunnel.state=='running'){
        return tunnel.status.url;
      }
      else if (tunnel.state=='exited'){
        if (tunnel.proto=='tcp'){
          let remoteport = tunnel.remoteport ? tunnel.remoteport : 'random';
          return tunnel.proto + ',' + remoteport;
        }else{
          return tunnel.proto;
        }
      }
      //service.state=='running' ? service.remoteport || service.status.url : ''
    }
  }
}


</script>

<style>
body {
  font-family: Helvetica, sans-serif;
}
.inline {
  display: inline;
}
.row {
  display: flex;
  flex-direction: row;
  align-items: center;
}


.demo-menu.demo-menu__lower-right .container {
  position: relative;
  width: 200px;
}
.background {
  background: white;
  /**height: 148px;**/
  /**width: 100%;**/
}
.background #banding-table {
  width: 100%;
}
.bar {
  box-sizing: border-box;
  position: relative;
  background: #3F51B5;
  color: white;
  height: 64px;
  width: 100%;
  padding: 16px;
}
.wrapper {
  box-sizing: border-box;
  position: absolute;
  right: 16px;
}
.mdl-dialog-container .mdl-dialog{
  width: 400px;
}
.mdl-spinner {
  width: 16px;
  height: 16px;
}
.mdl-spinner__circle {
  border-width: 2px;
}


</style>
