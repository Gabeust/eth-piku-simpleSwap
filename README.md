# 🧪 SimpleSwap DEX

A minimalistic implementation of a decentralized exchange (DEX) inspired by Uniswap V2, built with Solidity.  
It allows users to swap ERC-20 tokens, add/remove liquidity, and query prices.

---

## 📌 Description

This repository contains three smart contracts:

### ✅ ErosToken (ERX)
An ERC-20 token with an owner-restricted minting mechanism. Initial supply is 1,000,000 ERX.

### ✅ NinaToken (NINX)
Another ERC-20 token with the same structure and features as ErosToken.

### 🔁 SimpleSwap
A custom automated market maker (AMM) that allows users to:
- Add and remove liquidity
- Swap ERC-20 tokens
- Get price of tokenA in terms of tokenB
- Calculate swap amounts using Uniswap-style constant product formula

---

## 💻 Uso del Frontend (SimpleSwap DApp)

El frontend es una interfaz web que permite a los usuarios interactuar fácilmente con el contrato SimpleSwap:

- **Conectar Wallet:** Conectá tu MetaMask o wallet compatible con la DApp.

- **Intercambiar Tokens:** Ingresá la cantidad de token que querés intercambiar. La DApp calcula automáticamente el monto estimado de salida y el deslizamiento (slippage).

- **Aprobar Tokens:** El frontend realiza automáticamente las transacciones de `approve()` antes de hacer swaps, asegurando que el contrato tenga permiso para transferir tus tokens.

- **Agregar/Retirar Liquidez:** Proveé liquidez a pares de tokens o retirala fácilmente.

- **Precio y Slippage en Tiempo Real:** La interfaz actualiza dinámicamente los precios y los mínimos aceptables para protegerte contra el deslizamiento.

**Nota:** Asegurate de aprobar el gasto de tokens antes de realizar swaps o agregar liquidez; el frontend gestiona este flujo automáticamente para vos.

---


## 🔧 Features

- Liquidity provisioning
- LP shares tracked internally
- Constant product formula (`x * y = k`)
- Pricing and output estimate functions

---

## 🧱 Project Structure

```
📦 contracts/
 ┣ 📜 ErosToken.sol
 ┣ 📜 NinaToken.sol
 ┗ 📜 SimpleSwap.sol

📄 README.md
```

---

## 🚀 Deployment Steps (Using Remix or Hardhat)

1. Deploy `ErosToken` and `NinaToken`
2. Mint tokens to user accounts via `mint()`
3. Deploy `SimpleSwap`
4. Approve token transfers for the `SimpleSwap` contract
5. Add liquidity using `addLiquidity()`
6. Perform token swaps via `swapExactTokensForTokens()`

---

## 🧪 Example Interaction

```solidity
erosToken.approve(simpleSwap.address, 100000);
ninaToken.approve(simpleSwap.address, 100000);

simpleSwap.addLiquidity(
    erosToken.address,
    ninaToken.address,
    100000,
    100000,
    100000,
    100000,
    msg.sender,
    block.timestamp + 600
);
```

---

## 🛠 Requirements

- Solidity ^0.8.27
- OpenZeppelin Contracts (ERC20)
- Remix IDE or Hardhat (for local testing)

---

## 🧑‍💻 Author

**Gabriel** —  
Backend Developer | Solidity Smart Contracts | Java Specialist  
Argentina 🇦🇷
---

## 🛡 License

MIT License

---

## 📚 Resources

- [Uniswap V2 Docs](https://docs.uniswap.org/protocol/V2)
- [Solidity by Example](https://solidity-by-example.org/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/4.x/)
