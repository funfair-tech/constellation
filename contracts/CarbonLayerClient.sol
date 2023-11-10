// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

enum Intensity { High, Medium, Low, Invalid }

contract CarbonLayerClient is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    //TODO
    uint256 private constant ORACLE_PAYMENT = (1 * LINK_DIVISIBILITY) / 10; // 0.1 * 10**18
    
    // intensity
    Intensity public intensity;

    // TODO mix
    uint8 public biomass;
    uint8 public coal;
    uint8 public imports;
    uint8 public gas;
    uint8 public nuclear;
    uint8 public other;
    uint8 public hydro;
    uint8 public solar;
    uint8 public wind;


    event RequestIntensityFulfilled(
        bytes32 indexed requestId,
        string indexed intensity
    );

    /**
     * Sepolia
     * @dev LINK address in Sepolia network: 0x779877A7B0D9E8603169DdbD7836e478b4624789
     * @dev Check https://docs.chain.link/docs/link-token-contracts/ for LINK address for the right network
     */
    constructor(address _linkNetworkAddress) ConfirmedOwner(msg.sender) {
        setChainlinkToken(_linkNetworkAddress);
    }
   
    // 
    function requestIntensityDetails(address _oracle, string memory _jobId) public onlyOwner {
        Chainlink.Request memory req = buildChainlinkRequest(
            stringToBytes32(_jobId),
            address(this),
            this.fulfillIntensityDetails.selector
        );

        sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
    }

    function requestIntensity(address _oracle, string memory _jobId)
        public
        onlyOwner
    {
        Chainlink.Request memory req = buildChainlinkRequest(
            stringToBytes32(_jobId),
            address(this),
            this.fulfillIntensity.selector
        );

        sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
    }

    function fulfillIntensityDetails(
        bytes32 _requestId,
        string memory _intensity,
        uint8 _biomass,
        uint8 _coal
    ) public recordChainlinkFulfillment(_requestId) {
      Intensity parsedIntensity = parseIntensity(_intensity);
      require(parsedIntensity != Intensity.Invalid, "Invalid intensity value");

      emit RequestIntensityFulfilled(_requestId, _intensity);
      intensity = parsedIntensity;
      biomass = _biomass;
      coal = _coal;
    }

    function fulfillIntensity(
        bytes32 _requestId,
        string memory _intensity
    ) public recordChainlinkFulfillment(_requestId) {
      Intensity parsedIntensity = parseIntensity(_intensity);
      require(parsedIntensity != Intensity.Invalid, "Invalid intensity value");

      emit RequestIntensityFulfilled(_requestId, _intensity);
      intensity = parsedIntensity;
    }

    function getChainlinkToken() public view returns (address) {
        return chainlinkTokenAddress();
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    function cancelRequest(
        bytes32 _requestId,
        uint256 _payment,
        bytes4 _callbackFunctionId,
        uint256 _expiration
    ) public onlyOwner {
        cancelChainlinkRequest(
            _requestId,
            _payment,
            _callbackFunctionId,
            _expiration
        );
    }

  function parseIntensity(string memory _intensity) internal pure returns (Intensity) {
        if (compareStrings(_intensity, "High")) {
            return Intensity.High;
        } else if (compareStrings(_intensity, "Medium")) {
            return Intensity.Medium;
        } else if (compareStrings(_intensity, "Low")) {
            return Intensity.Low;
        } else {
            return Intensity.Invalid;
        }
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function stringToBytes32(string memory source)
        private
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }
}
