const Presale = artifacts.require('./Presale.sol');

contract('Presale', async (accounts) => {
	let instance;

	beforeEach(async function () {
		instance = await Presale.new();
	});

	it('should deploy', async() => {
		let owneraddy = await instance.owner.call();

		assert.equal(owneraddy, accounts[0]);
		assert.notEqual(instance.address, 0x0);
	})

	it('should accept payment (15e+17 minimum)', async() => {
		var amount = 15e+17;

		let purchase = await instance.sendTransaction({ value: amount, from: accounts[1] });
		let balance = await instance.balances.call(accounts[1]);

		assert.equal(balance, amount);
	})

	it('should not accept payment below minimum', async() => {
		var amount = 14e+17;

		try {
			await instance.sendTransaction({ value: amount, from: accounts[1] });
			assert.fail('Expected revert not received');
		} catch (error) {
			const revertFound = error.message.search('revert') >= 0;
			assert(revertFound, `Expected "revert", got ${error} instead`);
		}
	})

	it('should not accept payment after presale has ended', async() => {
		var amount = 15e+17;

		let end = await instance.EndPresale();

		try {
			await instance.sendTransaction({ value: amount, from: accounts[1] });
			assert.fail('Expected revert not received');
		} catch (error) {
			const revertFound = error.message.search('revert') >= 0;
			assert(revertFound, `Expected "revert", got ${error} instead`);
		}
	})

	it('should refund a purchase', async() => {
		var amount = 15e+17;

		let purchase = await instance.sendTransaction({ value: amount, from: accounts[1] });
		let balance = await instance.balances.call(accounts[1]);

		assert.equal(balance, amount);

		let refund = await instance.RefundPurchaser(accounts[1]);
		let newBalance = await instance.balances.call(accounts[1]);

		assert.equal(newBalance, 0);
	})

	it('should withdraw to the owner if needed', async() => {
		var amount = 15e+17;

		let purchase = await instance.sendTransaction({ value: amount, from: accounts[1] });
		let contractBalance = web3.eth.getBalance(instance.address);
		let ownerBalance = web3.eth.getBalance(accounts[0]);

		assert.equal(contractBalance, amount);

		let withdraw = await instance.withdraw();
		let contractBalance2 = web3.eth.getBalance(instance.address);
		let ownerBalance2 = web3.eth.getBalance(accounts[0]);
		
		assert.equal(contractBalance2, 0);
		assert.notEqual(ownerBalance2, ownerBalance);

	})

	it('should update cap', async() => {
		var newCap = 15000;

		let cap1 = await instance.presaleMaximum.call();
		console.log(cap1.toString());

		let updateCap = await instance.updateCap(newCap);

		let cap2 = await instance.presaleMaximum.call();
		console.log(cap2.toString());

		assert.notEqual(cap1, cap2);
	})

})