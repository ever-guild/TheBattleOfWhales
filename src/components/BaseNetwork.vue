<template>
  <div>
    <div class="container text-center mt-4">
      <b-alert style="background-color: rgb(93, 93, 97, 0.5) !important;" variant="outline-primary" class="text-light mt-4 mb-4" fade :show="systemAlert">{{ systemAlertMessage }}</b-alert>
    </div>
  </div>
</template>
<script lang="ts">
import Vue from 'vue'
import { getNetwork } from '@/wallet'
import { network } from '@/config'
export default Vue.extend({
  name: 'BaseNetwork',
  mounted() {
    getNetwork().then((_network) => {
      if (typeof _network == 'undefined') return
      this.$network = _network
      this.controlNetwork()
    })
    this.network = network
  },
  data() {
    return {
      systemAlert: false,
      systemAlertMessage: '',
      network: '',
    }
  },
  methods: {
    controlNetwork() {
      if (typeof this.$network == 'undefined') return
      if (this.network !== this.$network) {
        this.systemAlert = true
        this.systemAlertMessage = 'Switch EverWallet to the ' + this.network + ' network. You wallet using ' + this.$network
      } else {
        this.systemAlert = false
      }
    },
  },
  watch: {
    $network() {
      this.controlNetwork()
    },
  },
})
</script>
