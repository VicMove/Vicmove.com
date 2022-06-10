// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (finance/VestingWallet.sol)
pragma solidity ^0.8.0;


import "./Address.sol";
import "./BEPPausable.sol";
import "./IBEP20.sol";
import "./IERC721Enumerable.sol";

contract marketplace is BEPPausable {

    address public Treasury;
    address public LiquidPool;
    address public ShoseNFTContract;
    address public VIMContract;
    address public WBNBContract;
    uint256 public MinBnB;
    uint256 private tax;
    address public Pool2;
    mapping(uint256 => address) private shoseTranfer;

    mapping(uint256 => uint256) private shoseSell;
    mapping(uint256 => address) private shoseSeller;
    uint256[] private allTokensSell;

    event changeTreasury(address _Treasury);
    event changeLiquidPool(address _LiquidPool);
    event changeShoseNFTContract(address _ShoseNFTContract);
    event changeVIMContract(address _VIMContract);
    event changeMinBnB(uint256 _MinBnB);
    event eventtransferVicShose(address to,uint256 tokenId);
    event eventSellVicShose(uint256 tokenId,uint256 price);
    event eventCancelSellVicShose(uint256 tokenId);
    event eventBuyVicShose(uint256 tokenId);

    constructor() payable{ 
        Treasury = 0xcb3745379275252F4beB5d1094bF1a8A09F368b7;
        LiquidPool = 0xd295cF5D859B9Ed331cdF69c49A81Eff5e1Bee83;
        ShoseNFTContract = 0xC184af52Ca4E1B1f085aA8236Ff8508F52dc6eA7;
        VIMContract = 0x5bcd91C734d665Fe426A5D7156f2aD7d37b76e30;
        WBNBContract = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        Pool2 = 0xfA0E47A2d6a58b9fd7Ca1d4bFAADd11E8811824B;
        MinBnB = 1;
        tax = 5;
    }
    function setPool2(address _Pool2) external onlyOwner {
        Pool2 = _Pool2;
    }  
    function setTreasury(address _Treasury) external onlyOwner {
        Treasury = _Treasury;
        emit changeTreasury(Treasury);
    }  
    function setLiquidPool(address _LiquidPool) external onlyOwner {
        LiquidPool = _LiquidPool;
        emit changeLiquidPool(LiquidPool);
    } 
    function setShoseNFTContract(address _ShoseNFTContract) external onlyOwner {
        ShoseNFTContract = _ShoseNFTContract;
        emit changeShoseNFTContract(ShoseNFTContract);
    } 
    function setVIMContract(address _VIMContract) external onlyOwner {
        VIMContract = _VIMContract;
        emit changeVIMContract(VIMContract);
    } 
    function setMinBNB(uint256  _MinBnB) external onlyOwner {
        MinBnB = _MinBnB;
        emit changeMinBnB(MinBnB);
    } 
    function setTax(uint256 _Tax) external onlyOwner {
        require(_Tax<50);
        tax = _Tax;
    } 

    function getMINPrice() public view virtual returns (uint256) {
        uint256 wbnbbalance = IBEP20(WBNBContract).balanceOf(LiquidPool);
        uint256 vimbalance = IBEP20(VIMContract).balanceOf(LiquidPool);
        uint256 bnbprice = vimbalance/wbnbbalance;
        uint256 minprice = bnbprice * MinBnB / 10;
        return minprice;
    }

    function transferVicShose(address to,uint256 tokenId) external whenNotPaused {
        address from = msg.sender;
        require(IERC721Enumerable(ShoseNFTContract).isApprovedForAll(from,address(this)),"You need Approve For All to this contact");
        require(to != address(0),"Address can not zero");
        require(to != from,"From and To can not same");
        IERC721Enumerable(ShoseNFTContract).safeTransferFrom(from, to,tokenId);
        shoseTranfer[tokenId] = to;
        emit eventtransferVicShose(to,tokenId);
    }
    function checkShoseTranfer(uint256 tokenId) public view virtual returns (address) {
        return shoseTranfer[tokenId];
    }

    function SellVicShose(uint256 tokenId,uint256 price) external whenNotPaused {
        require(shoseSell[tokenId] == 0,"it is selling");
        address seller = msg.sender;
        require(IERC721Enumerable(ShoseNFTContract).ownerOf(tokenId) == seller,"seller need have this tokenid");
        require(IERC721Enumerable(ShoseNFTContract).isApprovedForAll(seller,address(this)),"You need Approve For All to this contact");
        require(price > 0, "Price > 0");
        addNFTSell(tokenId, price,seller);
        emit eventSellVicShose(tokenId,price);
    }

    function CancelSellVicShose(uint256 tokenId) external whenNotPaused {
        require(shoseSell[tokenId] > 0,"VicShose not in sell");
        address seller = msg.sender;
        require(IERC721Enumerable(ShoseNFTContract).ownerOf(tokenId) == seller,"seller need have this tokenid");
        removeNFTSell(tokenId);
        emit eventCancelSellVicShose(tokenId);
    }

    function BuyVicShose(uint256 tokenId) external whenNotPaused {
        address seller = shoseSeller[tokenId];
        require(shoseSell[tokenId] > 0,"VicShose not in sell");//phải đang được bán 
        require(IERC721Enumerable(ShoseNFTContract).ownerOf(tokenId) == seller,"seller need have this tokenid");//ngừoi bán và người sở hữu phải là 1
        require(IERC721Enumerable(ShoseNFTContract).isApprovedForAll(seller,address(this)),"You need Approve For All to this contact");
        address buyer = msg.sender;
        uint256 minprice = getMINPrice();
        uint256 buyPrice = minprice;
        uint256 sellPrice = shoseSell[tokenId];
        if(sellPrice > minprice){
            buyPrice = sellPrice;
        }
        require(IBEP20(VIMContract).allowance(buyer,address(this)) >= buyPrice * 10**18,"The money allowed is not enough to buy shoes. You need approve more VIM");//phải được quyền sử dụng VIM của buyer //quyền sử dụng VIM phải lớn hơn giá bán 
        IBEP20(VIMContract).transferFrom(buyer,address(this),buyPrice * 10**18); //lấy VIM của người mua
        IERC721Enumerable(ShoseNFTContract).safeTransferFrom(seller,buyer, tokenId);//Chuyển giày của người bán cho người mua
        //Tính phí bán giày
        uint256 fee = 0;
        if(sellPrice >= minprice){
            fee = sellPrice*tax/100;
        }else{
            if(sellPrice*tax/100 > minprice - sellPrice){
                fee = sellPrice*tax/100;
            }else{
                fee = minprice - sellPrice;
            }
        }
        IBEP20(VIMContract).transfer(seller, (buyPrice-fee) * 10**18);//Chuyển tiền được thụ hưởng cho người bán
        IBEP20(VIMContract).transfer(Treasury,fee * 10**18);//Chuyển phí bán giày vào quỹ cộng đồng
        shoseTranfer[tokenId] = buyer;//thống báo hệ thống là bán thành công sang chủ sở hữu mới
        removeNFTSell(tokenId);//xoá lệnh bán đi
        emit eventBuyVicShose(tokenId);//Call event
    }

    function removeNFTSell(uint256 tokenId) internal{
        delete shoseSell[tokenId];
        for(uint256 i = 0; i < allTokensSell.length; i++){
            if(allTokensSell[i] == tokenId){
                for(uint256 k = i; k < allTokensSell.length - 1; k++){
                    allTokensSell[k] = allTokensSell[k+1];
                }
                allTokensSell.pop();
                return;
            }
        }
    } 
    function addNFTSell(uint256 tokenId, uint256 price, address seller) internal{
        shoseSell[tokenId] = price;
        shoseSeller[tokenId] = seller;
        allTokensSell.push(tokenId);
        if(allTokensSell.length >= 2){
            for(uint256 i = allTokensSell.length-2; i >=0; i--){
                if(shoseSell[allTokensSell[i]] > price){
                    allTokensSell[i+1] = allTokensSell[i];
                    if(i==0){
                        allTokensSell[0] = tokenId;
                        return;
                    }
                }else{
                    allTokensSell[i+1] = tokenId;
                    return;
                }
            }
        }
    }

    function getSellingShose() external view returns (uint256[] memory _tokenID,address[] memory _owner, uint256[] memory _Price) {
        uint256 shoseShellCount = allTokensSell.length;
        uint256[] memory Price = new uint256[](shoseShellCount);
        address[] memory owner = new address[](shoseShellCount);
        for (uint256 i = 0; i < shoseShellCount; i++) {
            if(IERC721Enumerable(ShoseNFTContract).ownerOf(allTokensSell[i]) == shoseSeller[allTokensSell[i]]){
                Price[i] = shoseSell[allTokensSell[i]];
                owner[i] = shoseSeller[allTokensSell[i]];
            }else{
                Price[i] = 0;
                owner[i] = address(0);
            }
        }
        return (allTokensSell,owner,Price);
    }
    
    
    function getBalanceToken(address token) public view virtual returns (uint256) {
        return IBEP20(token).balanceOf(address(this));
    }
    function sentT2Pool2Token(address tokenaddress, uint256 amount) external onlyOwner {
        uint256 newBalance = IBEP20(tokenaddress).balanceOf(address(this));
        require(amount>0 && amount<=newBalance,"Amount > 0 && < Balance");
        IBEP20(tokenaddress).transfer(Pool2, amount);
    }

    function getBalanceBNB() public view virtual returns (uint256) {
        return address(this).balance;
    }
    function sentT2Pool2BNB(uint256 amount) external onlyOwner {
        uint256 newBalance = address(this).balance;
        require(amount>0 && amount<=newBalance,"Amount > 0 && < Balance");
        payable(Pool2).transfer(amount);
    }
    
    function test() external {
        require(IBEP20(VIMContract).allowance(msg.sender,address(this)) >= 100 * 10**18,"The money allowed is not enough to buy shoes. You need approve more VIM");//phải được quyền sử dụng VIM của buyer //quyền sử dụng VIM phải lớn hơn giá bán 
        IBEP20(VIMContract).transferFrom(msg.sender,address(this),100 * 10**18); //lấy VIM của người mua
    }
    receive() external payable {}
}