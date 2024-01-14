// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Token} from "./ERC20Token.sol";

/**
 * @title TokenSale
 * @notice This contract manages token sales, presale, and public sale contributions.
 */
contract TokenSale is Ownable(msg.sender) {
	uint256 private salesCounter;
	mapping(string => uint256) public symbolToId;

	// Struct to represent a token sale
	struct Sale {
		address token;
		uint256 startTime;
		uint256 presaleMaxCap;
		uint256 presaleMinContribution;
		uint256 presaleMaxContribution;
		uint256 presaleContributions;
		uint256 publicMaxCap;
		uint256 publicMinContribution;
		uint256 publicMaxContribution;
		uint256 publicContributions;
	}

	/// @dev each sale is given an id
	mapping(uint256 => Sale) public idToSale; // id => Sale


	mapping(address => mapping(uint256 => uint256)) public userContributions; // user-address => (id => amt)
	mapping(address => mapping(uint256 => uint256)) public userPresales;
	mapping(address => mapping(uint256 => uint256)) public userPublicSales;

	uint256 public constant SALE_START_DURATION = 86400; // 1 day
	uint256 public constant PRESALE_DURATION = 86400; // 1 day
	uint256 public constant PUBLIC_SALE_DURATION = 259200; // 3 days

	// Events
	event SaleCreated(uint256 indexed, string indexed, string indexed);
	event PresaleContribution(address, uint256);
	event PublicContribution(address, uint256);
	event ContributionClaimed(address, uint256);
	event TokensMinted(address, uint256);
	event PublicSaleContribution(address, uint256);

	// Errors
	error Token_Invalid();
	error Token_DuplicateSale();
	error MaxCap_Reached();
	error Contribution_Error();
	error Eth_Transaction_Failed();
	error Invalid_Claim_Contributions();
	error Zero_Claim_Error();
	error Invalid_Claim();
	error Error_Address_Zero();
	error Sale_PresaleNotStarted();
	error Sale_PresaleEnded();
	error Sale_PublicSaleNotStarted();
	error Sale_PublicSaleEnded();
	error Sale_NotEnded();

	/**
     * @notice Creates a new token sale.
     * @dev The token origin/creation is done within the contract
     * @param _name The name of the token.
     * @param _symbol The symbol of the token.
     * @param _presaleMaxCap The maximum cap for the presale.
     * @param _presaleMinContribution The minimum contribution for the presale.
     * @param _presaleMaxContribution The maximum contribution for the presale.
     * @param _publicMaxCap The maximum cap for the public sale.
     * @param _publicMinContribution The minimum contribution for the public sale.
     * @param _publicMaxContribution The maximum contribution for the public sale.
     * @return The ID of the created sale.
     */
	function createSale(
		string memory _name,
		string memory _symbol,
		uint256 _presaleMaxCap,
		uint256 _presaleMinContribution,
		uint256 _presaleMaxContribution,
		uint256 _publicMaxCap,
		uint256 _publicMinContribution,
		uint256 _publicMaxContribution
	) external onlyOwner returns (uint256) {
		if (symbolToId[_symbol] != 0) revert Token_DuplicateSale();

		salesCounter = salesCounter + 1;
		ERC20Token token = new ERC20Token(_name, _symbol);
		token.approve(address(this), type(uint).max);
		symbolToId[_symbol] = salesCounter;

		idToSale[salesCounter] = Sale(
			address(token),
			block.timestamp,
			_presaleMaxCap,
			_presaleMinContribution,
			_presaleMaxContribution,
			0,
			_publicMaxCap,
			_publicMinContribution,
			_publicMaxContribution,
			0
		);

		emit SaleCreated(salesCounter, _name, _symbol);

		return salesCounter;
	}

	/**
     * @notice Modifier to check if the presale is ongoing.
     * @param _id The ID of the sale.
     */
	modifier preSale(uint256 _id) {
		uint256 startTime = idToSale[_id].startTime;
		if (startTime + SALE_START_DURATION > block.timestamp) revert Sale_PresaleNotStarted();
		if (startTime + SALE_START_DURATION + PRESALE_DURATION < block.timestamp) revert Sale_PresaleEnded();
		_;
	}

	/**
     * @notice Modifier to check if the public sale is ongoing.
     * @param _id The ID of the sale.
     */
	modifier publicSale(uint256 _id) {
		uint256 startTime = idToSale[_id].startTime;
		if (startTime + SALE_START_DURATION + PRESALE_DURATION > block.timestamp) revert Sale_PublicSaleNotStarted();
		if (startTime + SALE_START_DURATION + PRESALE_DURATION + PUBLIC_SALE_DURATION < block.timestamp)
			revert Sale_PublicSaleEnded();
		_;
	}

	/**
     * @notice Modifier to check if the sale has ended.
     * @param _id The ID of the sale.
     */
	modifier saleEnded(uint256 _id) {
		uint256 startTime = idToSale[_id].startTime;
		if (startTime + SALE_START_DURATION + PRESALE_DURATION + PUBLIC_SALE_DURATION > block.timestamp)
			revert Sale_NotEnded();
		_;
	}

	/**
     * @notice Contribute to the presale.
     * @param _id The ID of the sale.
     */
	function contributeToPresale(uint256 _id) public payable preSale(_id) {
		if (idToSale[_id].presaleContributions >= idToSale[_id].presaleMaxCap) {
			revert MaxCap_Reached();
		}

		uint256 userContribution = userContributions[msg.sender][_id];
		if (
			userContribution + msg.value > idToSale[_id].presaleMaxContribution ||
			userContribution + msg.value < idToSale[_id].presaleMinContribution
		) {
			revert Contribution_Error();
		}

		userPresales[msg.sender][_id] += 1;
		idToSale[_id].presaleContributions += msg.value;
		userContributions[msg.sender][_id] += msg.value;

		(bool sent, ) = address(this).call{value: msg.value}("");
		if (!sent) {
			revert Eth_Transaction_Failed();
		}
		_distributeTokens(_id, msg.value);

		emit PresaleContribution(msg.sender, msg.value);
	}

	/**
     * @notice Contribute to the public sale.
     * @param _id The ID of the sale.
     */
	function contributeToPublicSale(uint256 _id) public payable publicSale(_id) {
		if (idToSale[_id].publicContributions >= idToSale[_id].publicMaxCap) {
			revert MaxCap_Reached();
		}

		uint256 userContribution = userContributions[msg.sender][_id];
		if (
			userContribution + msg.value > idToSale[_id].publicMaxContribution ||
			userContribution + msg.value < idToSale[_id].publicMinContribution
		) {
			revert Contribution_Error();
		}

		userPublicSales[msg.sender][_id] += 1;
		idToSale[_id].publicContributions += msg.value;
		userContributions[msg.sender][_id] += msg.value;

		_distributeTokens(_id, msg.value);

		emit PublicSaleContribution(msg.sender, msg.value);
	}

	/**
     * @notice Claim contributions after the sale has ended.
     * @param _id The ID of the sale.
     */
	function claimContribution(uint256 _id) public payable saleEnded(_id) {
		uint256 claimableAmount = userContributions[msg.sender][_id];
		if (claimableAmount < 1) revert Invalid_Claim_Contributions();

		if (
			idToSale[_id].publicContributions >= idToSale[_id].publicMaxCap &&
			idToSale[_id].presaleContributions >= idToSale[_id].presaleMaxCap
		) {
			revert Invalid_Claim();
		}

		Sale storage sale = idToSale[_id];

		sale.presaleContributions -= userPresales[msg.sender][_id];
		sale.publicContributions -= userPublicSales[msg.sender][_id];

		userPresales[msg.sender][_id] = 0;
		userPublicSales[msg.sender][_id] = 0;

		userContributions[msg.sender][_id] -= claimableAmount;

		ERC20Token(idToSale[_id].token).transferFrom(msg.sender, address(this), claimableAmount);

		emit ContributionClaimed(msg.sender, claimableAmount);
	}

	/**
     * @notice Internal function to distribute tokens to the contributor.
     * @param _saleId The ID of the sale.
     * @param _amount The amount of tokens to distribute.
     */
	function _distributeTokens(uint256 _saleId, uint256 _amount) internal {
		address token = idToSale[_saleId].token;
		ERC20Token(token).mint(msg.sender, _amount);
		emit TokensMinted(msg.sender, _amount);
	}

	/**
     * @notice External function to distribute tokens to a specified address.
     * @param _to The address to which tokens will be distributed.
     * @param _saleId The ID of the sale.
     * @param _amount The amount of tokens to distribute.
     */
	function distributeTokens(address _to, uint256 _saleId, uint256 _amount) external onlyOwner {
		if (_to == address(0)) revert Error_Address_Zero();
		ERC20Token(idToSale[_saleId].token).mint(_to, _amount);
		emit TokensMinted(_to, _amount);
	}

	/**
     * @notice Get sale details by sale ID.
     * @param _id The ID of the sale.
     * @return Sale details.
     */
	function getSaleById(uint256 _id) public view returns (Sale memory) {
		if (_id == 0 || _id > salesCounter) revert Token_Invalid();
		return idToSale[_id];
	}

	/**
     * @notice Get the contribution amount of a user for a specific sale.
     * @param _user The address of the user.
     * @param _id The ID of the sale.
     * @return User contribution amount.
     */
	function getUserContributions(address _user, uint256 _id) public view returns (uint256) {
		return userContributions[_user][_id];
	}

	/**
     * @notice Get the sale ID by symbol.
     * @param _symbol The symbol of the token.
     * @return The ID of the sale.
     */
	function getSaleId(string memory _symbol) external view returns (uint256) {
		uint256 id = symbolToId[_symbol];
		if (id == 0) {
			revert Token_Invalid();
		}
		return id;
	}

	/**
     * @notice Fallback function to accept Ether.
     */
	receive() external payable {}

	/**
     * @notice Fallback function to accept Ether.
     */
	fallback() external payable {}
}
