<template>
  <div>
    <div class="container mt-5 mb-5" id="fishBox">
      <div style="margin-right: 1em">
        <div id="leftFish" ref="leftFish">🐋</div>
        <div id="totalAmountSide1" class="mt-4 mb-4 text-center text-light h4">{{ totalAmountSide1 }} EVER</div>

        <b-tooltip :show.sync="showTooltipLeft" target="totalAmountSide1" placement="top">
          {{ amountTooltipMsgLeft }}
        </b-tooltip>
        <div id="leftFishInputAmount" v-if="userBox">
          <b-form-input autocomplete="off" block v-model="fishInputAmount1"></b-form-input>
        </div>
        <div id="leftFishBtn" v-if="userBox">
          <b-button id="betBtnLeft" block variant="outline-primary" @click="_bet(1)">Bet</b-button>
          <!-- <b-tooltip target="betBtnLeft" triggers="click">Sent</b-tooltip>  -->
        </div>
        <div id="leftAddr" class="mt-3">
          <b-input-group size="sm">
            <b-form-input v-on:focus="$event.target.select()" ref="leftAddr" class="link-light" v-model="RD1Address"> </b-form-input>
            <b-input-group-append>
              <b-button variant="outline-primary" id="copyBtnLeft" @click="_copy(1)">Copy</b-button>
              <b-tooltip variant="dark" target="copyBtnLeft" triggers="click">Copied</b-tooltip>
              <b-icon icon="question-circle" id="leftBetTip" variant="light" aria-label="Help"></b-icon>
              <b-tooltip target="leftBetTip" variant="dark">Direct bet — send to this address. Min amount 1 Ever.</b-tooltip>
            </b-input-group-append>
          </b-input-group>
        </div>
      </div>
      <div>
        <div id="rightFish" ref="rightFish">🐋</div>
        <div id="totalAmountSide2" class="mt-4 mb-4 text-center text-light h4">{{ totalAmountSide2 }} EVER</div>
        <b-tooltip :show.sync="showTooltipRight" target="totalAmountSide2" placement="top">
          {{ amountTooltipMsgRight }}
        </b-tooltip>
        <div id="rightFishInputAmount" v-if="userBox">
          <b-form-input autocomplete="off" v-model="fishInputAmount2"></b-form-input>
        </div>
        <div id="rightFishBtn" v-if="userBox">
          <b-button id="betBtnRight" variant="outline-primary" @click="_bet(2)">Bet</b-button>
          <!-- <b-tooltip target="betBtnRight">Sent</b-tooltip> -->
        </div>
        <div id="RightAddr" class="mt-3">
          <b-input-group size="sm">
            <b-form-input v-on:focus="$event.target.select()" ref="rightAddr" class="link-light" v-model="RD2Address"> </b-form-input>
            <b-input-group-append>
              <b-button variant="outline-primary" id="copyBtnRight" @click="_copy(2)">Copy</b-button>
              <b-tooltip target="copyBtnRight" variant="dark" triggers="click">Copied</b-tooltip>
              <b-icon icon="question-circle" id="rightBetTip" variant="light" aria-label="Help"></b-icon>
              <b-tooltip target="rightBetTip" variant="dark">Direct bet — send to this address. Min amount 1 Ever.</b-tooltip>
            </b-input-group-append>
          </b-input-group>
        </div>
      </div>
    </div>
    <div class="text-center">
      <b-button v-if="roundState == 'Finished' && winState" variant="outline-primary" class="mb-4" :href="`./#/round/${roundContractAddress}`">Claim reward</b-button>
    </div>
    <div class="container text-light text-center">
      <span>Round state: {{ roundState }}</span>
    </div>
    <div class="container">
      <b-progress :value="progressValue" height="0.4rem" variant="secondary" :max="progressMax" :show-value="false"></b-progress>
    </div>
    <div class="container text-light text-center">
      <span>{{ countDown }}</span>
    </div>
    <div class="container text-center text-light mt-4 mb-4">Time: {{ roundStart }} — {{ roundEnd }}</div>
    <div class="container text-center mt-4">
      <b-alert style="background-color: rgb(93, 93, 97, 0.5) !important;" variant="outline-primary" class="text-light mt-4 mb-4" fade :show="systemAlert">{{ systemAlertMessage }}</b-alert>
    </div>
    <BaseNetwork></BaseNetwork>
    <div class="container text-center mt-4">
      <b-alert variant="dark" mt-4 mb-4 fade :show="betAlert">{{ betAlertMessage }}</b-alert>
    </div>
    <div v-if="userBox" class="mt-4">
      <div class="text-center text-light mt-4 h5">My bets:</div>
      <div id="userAmountBox">
        <div class="mt-4 mb-4 text-center text-light h5">{{ userAmountSide1 }} Ever</div>
        <div class="mt-4 mb-4 text-center text-light h5">{{ userAmountSide2 }} Ever</div>
      </div>
    </div>
    <div id="roundContract" class="container text-center text-light mt-4 footer">
      Round contract: <b-link class="link-light" :href="explorer + '/accounts/accountDetails?id=' + roundContractAddress" target="_blank">{{ roundContractAddress }}</b-link>
    </div>
  </div>
</template>
<script lang="ts">
import Vue from 'vue'
import { RD1Address, RD2Address, roundDuration } from '@/config'
import { authState, bet, getRoundTime, getRoundContractAddress, getBetsData, getUserBetsData, setUpSubscriptions, tearDownSubscriptions } from '@/wallet'
import { sleep } from '@/utils'
import { explorer } from '@/connection'
import moment from 'moment'

export default Vue.extend({
  name: 'HomeView',
  mounted() {
    window.setInterval(() => {
      this.currentTime = Date.now()
    }, 100)
    this.updateAll()
  },
  data() {
    return {
      authTrigger: false,
      fishInputAmount1: 0,
      fishInputAmount2: 0,
      systemAlert: false,
      systemAlertMessage: '',
      betAlert: false,
      betAlertMessage: '',
      roundStart: '',
      roundEnd: '',
      roundStartTimestamp: 0,
      roundEndTimestamp: 0,
      roundContractAddress: '',
      totalAmountSide1: 0,
      totalAmountSide2: 0,
      userAmountSide1: 0,
      userAmountSide2: 0,
      userBox: false,
      RD1Address: '',
      RD2Address: '',
      betBtnDisabled: false,
      leftFishSize: '5em',
      rightFishSize: '5em',
      currentTime: Date.now(),
      progressMax: 100,
      progressValue: 0,
      roundState: '',
      explorer: '',
      prevTotalData: { side1: 0, side2: 0 },
      amountTooltipMsgLeft: '',
      amountTooltipMsgRight: '',
      showTooltipLeft: false,
      showTooltipRight: false,
      winState: false,
      countDown: 0,
    }
  },
  methods: {
    async _bet(side: 1 | 2) {
      if ((await authState()) == false) {
        this.systemAlert = true
        this.systemAlertMessage = 'Connect your wallet'
        await sleep(5000)
        this.systemAlert = false
        return
      }
      if (this.roundState == 'Finished') {
        this.systemAlert = true
        this.systemAlertMessage = 'This round is finished. The next round will be in one minute'
        await sleep(5000)
        this.systemAlert = false
        return
      }
      if (this.roundState == 'Prepearing...') {
        this.systemAlert = true
        this.systemAlertMessage = 'This round is prepearing now. The next round will be in one minute'
        await sleep(5000)
        this.systemAlert = false
        return
      }
      const amount = this[('fishInputAmount' + side) as keyof Vue]
      if (isNaN(amount) || amount < 1) {
        this.systemAlertMessage = 'Min bet 1 EVER'
        this.systemAlert = true
        await sleep(3000)
        this.systemAlert = false
        return
      }
      await bet(side, Number(amount) * 1e9)
    },
    async _copy(side: number) {
      if (side == 1) (this.$refs.leftAddr as HTMLInputElement).focus()
      if (side == 2) (this.$refs.rightAddr as HTMLInputElement).focus()
      document.execCommand('copy')
      await sleep(1000)
      const toolTipId = side == 1 ? 'copyBtnLeft' : 'copyBtnRight'
      this.$root.$emit('bv::hide::tooltip', toolTipId)
    },
    updateBetsData() {
      getRoundTime().then((time) => {
        this.roundStart = new Date(time.roundStart * 1000).toLocaleTimeString()
        this.roundEnd = new Date(time.roundEnd * 1000).toLocaleTimeString()
        getRoundContractAddress(time.roundStart, time.roundEnd).then((a) => {
          this.roundContractAddress = a.toString()
        })
      })
      getBetsData().then((data) => {
        this.totalAmountSide1 = data.side1
        this.totalAmountSide2 = data.side2
        //this.updateFishSize(data.side1, data.side2)
      })
      getUserBetsData().then((data) => {
        if (typeof data == 'undefined') return
        this.userAmountSide1 = data.side1
        this.userAmountSide2 = data.side2
        this.userBox = true
      })
    },
    updateRoundState() {
      if (this.currentTime < this.roundStartTimestamp + 60 * 1000) {
        this.roundState = 'Prepearing...'
        this.countDown = moment
          .unix(60 - (Date.now() - this.roundStartTimestamp) / 1000)
          .utc()
          .format('mm [:] ss')
      } else if (this.currentTime > this.roundStartTimestamp + 60 * 1000 && this.currentTime < this.roundEndTimestamp) {
        this.roundState = 'Running'
        this.countDown = moment
          .unix(roundDuration - (roundDuration * this.progressValue) / 100)
          .utc()
          .format('HH [:] mm [:] ss')
      } else if (this.currentTime > this.roundEndTimestamp) {
        this.roundState = 'Finished'
        if (this.userAmountSide1 > 0 && this.totalAmountSide1 > this.totalAmountSide2) this.winState = true
        if (this.userAmountSide2 > 0 && this.totalAmountSide2 > this.totalAmountSide1) this.winState = true
      }
    },
    updateAll() {
      getRoundTime().then((time) => {        
        this.roundStart = new Date(time.roundStart * 1000).toLocaleTimeString()
        this.roundEnd = new Date(time.roundEnd * 1000).toLocaleTimeString()
        this.roundStartTimestamp = time.roundStart * 1000
        this.roundEndTimestamp = time.roundEnd * 1000
        getRoundContractAddress(time.roundStart, time.roundEnd).then((a) => {
          this.roundContractAddress = a.toString()
        })
      })
      getBetsData().then((data) => {
        this.totalAmountSide1 = data.side1
        this.totalAmountSide2 = data.side2
        this.prevTotalData = { side1: data.side1, side2: data.side2 }
      })
      getUserBetsData().then((data) => {
        if (typeof data == 'undefined') {
          this.userBox = false
          return
        }
        this.userAmountSide1 = data.side1
        this.userAmountSide2 = data.side2
        this.userBox = true
      })
      this.RD1Address = RD1Address
      this.RD2Address = RD2Address
      this.systemAlert = false
      this.explorer = explorer()

      tearDownSubscriptions().then(() => {
        setUpSubscriptions()
      })
    },
  },
  watch: {
    async $roundTransactions() {
      if (this.roundState !== 'Running') return

      const currTotalData: { side1: number; side2: number } | undefined = await getUserBetsData()
      if (typeof currTotalData == 'undefined') return
      //if no changes exit
      if (currTotalData.side1 > this.prevTotalData.side1 && currTotalData.side2 > this.prevTotalData.side2) return

      let amount: number

      if (currTotalData.side1 > this.prevTotalData.side1) {
        amount = currTotalData.side1 - this.prevTotalData.side1
        this.amountTooltipMsgLeft = '+' + amount.toString()
        this.showTooltipLeft = true
        await sleep(5e3)
        this.showTooltipLeft = false
      } else if (currTotalData.side2 > this.prevTotalData.side2) {
        amount = currTotalData.side2 - this.prevTotalData.side2
        this.amountTooltipMsgRight = '+' + amount.toString()
        this.showTooltipRight = true
        await sleep(5e3)
        this.showTooltipRight = false
      } else {
        return
      }
      this.prevTotalData = currTotalData

      this.updateBetsData()
    },
    $permissionsChanged() {
      this.updateAll()
    },
    currentTime(_, currentTime) {
      if (this.roundEndTimestamp == 0) return
      //wait minute and update all
      if (currentTime > this.roundEndTimestamp) {
        if (currentTime > this.roundEndTimestamp + 60 * 1000) {
          this.updateAll()
        }
        this.progressValue = 100

        this.updateRoundState()
        return
      }
      this.updateRoundState()
      this.progressValue = 100 - ((this.roundEndTimestamp - currentTime) / 1000 / (roundDuration - 60)) * 100 // todo change interval value
    },
  },
})
</script>
<style scoped>
#leftFish {
  transform: scale(-1, 1);
  font-size: 5em;
}
#rightFish {
  font-size: 5em;
}
#fishBox,
#userAmountBox {
  display: flex;
  justify-content: space-around;
}
#links {
  display: flex;
  justify-content: space-around;
}
#leftFishInputAmount,
#rightFishInputAmount {
  width: 5em;
}
#leftFishBtn button,
#rightFishBtn button {
  margin-top: 1em;
  width: 5em;
}

#leftBetTip,
#rightBetTip {
  margin-left: 0.5em;
}

#copyBtnLeft,
#copyBtnRight {
  border-top-left-radius: 0;
  border-bottom-left-radius: 0;
}

#roundContract {
  word-break: break-all;
}
</style>
