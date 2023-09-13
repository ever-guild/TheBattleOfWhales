pragma ever-solidity >=0.71.0;

import "./Bet.sol";

contract Round {
    TvmCell static betCode;

    uint32 public static roundStart;
    uint32 public static roundEnd;

    address public static RD1;
    address public static RD2;

    uint128 public side1 = 0;
    uint128 public side2 = 0;

    //todo deploy constructor https://github.com/tonlabs/samples/blob/master/solidity/17_SimpleWallet.sol#L23
    //можно ли передеплоить в один и тот же конструктор c
    // деплоить имеет право только кто-то с определенным клчем

    function deployBetContract(address player) public view returns (address) {
        return
            new Bet{
                stateInit: buildBetContractInitData(player),
                value: 1e8,
                flag: 0
            }(); //pay deploying fee from value
    }

    function buildBetContractInitData(
        address player
    ) public view returns (TvmCell) {
        return
            tvm.buildStateInit({
                code: betCode,
                varInit: {
                    roundStart: roundStart,
                    roundEnd: roundEnd,
                    player: player,
                    round: address(this)
                },
                contr: Bet,
                pubkey: tvm.pubkey()
            });
    }

    function calcBetAddress(address player) public view returns (address) {
        return address(tvm.hash(buildBetContractInitData(player)));
    }

    function placeBet(uint2 side, address player, uint128 betValue) public {
        require(side == 1 || side == 2, 101, "Wrong side");
        address sender = side == 1 ? RD1 : RD2;
        require(sender == msg.sender, 101, "Onluy RD contract can send");
        require(
            block.timestamp > roundStart && block.timestamp < roundEnd,
            102,
            "Wrong time"
        );
        // I don't know is BetContracts exists or not, then trying to deploying it
        address betAddress = deployBetContract(player);

        //flag 0: pay fee from value because bet value is a msg.value as a param
        Bet(betAddress).storeBet{value: 1e8, flag: 0}(betValue, side);

        if (side == 1) side1 += betValue;
        else side2 += betValue;
    }

    function claimReward(
        address player,
        uint128 amountOnSide1,
        uint128 amountOnSide2
    ) public view {
        require(calcBetAddress(player) == msg.sender, 102, "Wrong bet address");

        uint128 reward = calcReward(amountOnSide1, amountOnSide2);
        //The processing fee is the 1% from returned reward
        uint128 processingFee = calcProcessingFee(reward);
        reward = reward - processingFee;
        //todo Where processing fee will go?
        player.transfer({value: reward, flag: 64});
    }

    //1% or minimal 0.2 ever
    function calcProcessingFee(uint128 reward) public pure returns (uint128) {
        uint128 processingFee = reward / 100;
        return processingFee > 2e8 ? processingFee : 2e8;
    }

    function calcReward(
        uint128 amountOnSide1,
        uint128 amountOnSide2
    ) public view returns (uint128) {
        if (side1 == side2) {
            return amountOnSide1 + amountOnSide2;
        }
        if (side1 > side2) {
            return amountOnSide1 + (amountOnSide1 / side1) * side2;
        }

        if (side2 > side1) {
            return amountOnSide2 + (amountOnSide2 / side2) * side1;
        }
    }

    function getBetsData() public view returns (uint128, uint128) {
        return (side1, side2);
    }
}
