Generalised pre/post transfer hook/ Access control
- https://soroban.stellar.org/docs/fundamentals-and-concepts/authorization 
- https://docs.openzeppelin.com/contracts/2.x/access-control

SeedCore is the generalised extension interface that uses the diamond pattern. All SeedCores are extensions of the underlying contract and executed in SeedShare rather than externally. It allows SeedCores to use internal functions such as _mint(). It also allows SeedCores to implement an array of functions that are callable via the SeedShare contract rather having to be called directly. However, the before and after token hooks still apply. SeedCore functions must be appropriately bundled so that for example, using callSeedCore, the Shareholder registry is not upgraded twice. The SeedShare factory features a means of deploying and adding SeedCore to a Share contract.  Create a hook/interface for services so that services actions can be pre-validated with services, like ERC1155 receiver hook. Allows decentralised services to create a trustless environment by using hooks?

