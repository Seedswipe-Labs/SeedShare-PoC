# SeedShare

**Welcome to SeedShare: an ERC1155-Based multi-token Share contract, Shareholder registry and compliance suite.**

SeedShare is a toolkit for asset tokenisation, allowing entrepreneurs to create and manage tokenised equity, automate compliance and raise venture funding. For investors, SeedShare provides a platform to realise unprecedented liquidity on assets that would have previously been immobile, enabling equity Shares to be traded like any other crypto asset.

## SeedShare.sol

SeedShare is an ERC1155 Based tokenised equity contract. It provides all the functions traditionally associated with an ERC1155 token contract, plus additional issuer controls designed (and legally required in some jurisdictions) to support for equity Shares. These features include forced transfers and Share recovery in the event that a Shareholder has lost access to their wallet.

## SeedCoreCompliance.sol

SeedCoreCompliance works in tandem with SeedShare and the SeedBaseClaimRegistry, recording which attributes a prospective Shareholder must have in order to receive Shares. These attributes are known as claims. Unless a user is whitelisted, when a Share transfer is initiated the SeedCoreCompliance contract iterates through the necessary claims, comparing them against the claims held by the prospective Shareholder in the SeedBaseClaimRegistry. 

## SeedCoreRegistry.sol

SeedCoreRegistry keeps an on-chain record of the Shareholders of its corresponding SeedShare contract. It then uses this record to enforce limit-Based compliance checks, such as ensuring that a Share transfer does not result in too many Shareholders, fractional Shareholdings or  that a Shareholder has not been frozen by the owner-operator.



SeedCore is the generalised extension interface that uses the diamond pattern.

All SeedCores are extensions of the underlying contract and executed in SeedShare rather than externally.

It allows SeedCores to use internal functions such as _mint()

It also allows SeedCores to implement an array of functions that are callable via the SeedShare contract rather having to be called directly.

However, the before and after token hooks still apply. SeedCore functions must be appropriately bundled so that for example, using callSeedCore, the Shareholder registry is not upgraded twice.

The SeedShare factory features a means of deploying and adding SeedCore to a Share contract. 

Extensions:
	Registry
	Compliance 
	Delegates
	
	Script
		Minimal proxy erc20 factory

	Signer
	SAFT/SAFE/SAFTE/SAFET?
	Direct sale
	Crowd sale
	Vesting

Create a hook/interface for services so that services actions can be pre-validated with services, like ERC1155 receiver hook
Allows decentralised services to create a trustless environment by using hooks?