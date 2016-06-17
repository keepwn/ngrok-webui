import VueMdl from 'vue-mdl'
import VueResource from 'vue-resource'
import Vue from 'vue'
import App from './App.vue'

Vue.use(VueMdl)
Vue.use(VueResource)

new Vue({
  el: 'body',
  components: { App }
})
