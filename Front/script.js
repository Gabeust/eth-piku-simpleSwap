let web3;
let swapContract;
let isWalletConnected = false;
const SWAP_CONTRACT_ADDRESS = "0xC63b31a503B89f5Aebf42630E0D2B2256D03d45c";

const SWAP_ABI = [
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "tokenA",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "tokenB",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "amountADesired",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "amountBDesired",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "amountAMin",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "amountBMin",
				"type": "uint256"
			},
			{
				"internalType": "address",
				"name": "to",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "deadline",
				"type": "uint256"
			}
		],
		"name": "addLiquidity",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "amountA",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "amountB",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "liquidityMinted",
				"type": "uint256"
			}
		],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "amountIn",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "reserveIn",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "reserveOut",
				"type": "uint256"
			}
		],
		"name": "getAmountOut",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "amountOut",
				"type": "uint256"
			}
		],
		"stateMutability": "pure",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "tokenA",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "tokenB",
				"type": "address"
			}
		],
		"name": "getPrice",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "price",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"name": "liquidity",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "tokenA",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "tokenB",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "liquidityAmount",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "amountAMin",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "amountBMin",
				"type": "uint256"
			},
			{
				"internalType": "address",
				"name": "to",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "deadline",
				"type": "uint256"
			}
		],
		"name": "removeLiquidity",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "amountA",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "amountB",
				"type": "uint256"
			}
		],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"name": "reserves",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "tokenAReserve",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "tokenBReserve",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "amountIn",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "amountOutMin",
				"type": "uint256"
			},
			{
				"internalType": "address[]",
				"name": "path",
				"type": "address[]"
			},
			{
				"internalType": "address",
				"name": "to",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "deadline",
				"type": "uint256"
			}
		],
		"name": "swapExactTokensForTokens",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "amountOut",
				"type": "uint256"
			}
		],
		"stateMutability": "nonpayable",
		"type": "function"
	}
]
const TOKENS = [
	{ name: "ERX", address: "0x23B0B06213c5F0c824fcAb3FAcb89339B80d4107", icon: "🐶" },
	{ name: "NINX", address: "0x296b4fC2593595EE485aB0C471dF7F56b5b80Cc6", icon: "🐱" }
];
const ERC20_ABI = [
	{
		constant: true,
		inputs: [{ name: "_owner", type: "address" }],
		name: "balanceOf",
		outputs: [{ name: "balance", type: "uint256" }],
		type: "function"
	},
	{
		constant: false,
		inputs: [
			{ name: "_spender", type: "address" },
			{ name: "_value", type: "uint256" }
		],
		name: "approve",
		outputs: [{ name: "success", type: "bool" }],
		type: "function"
	},
	{
		constant: true,
		inputs: [
			{ name: "_owner", type: "address" },
			{ name: "_spender", type: "address" }
		],
		name: "allowance",
		outputs: [{ name: "remaining", type: "uint256" }],
		type: "function"
	}
];

// --- Inicialización al cargar la página ---
document.addEventListener("DOMContentLoaded", async() => {
	populateTokenDropdowns();
	loadHistory();
	// Verificar si estaba conectado (solo para esta sesión)
	const wasConnected = sessionStorage.getItem("walletConnected") === "true";

	// Verificamos que haya wallet y cuenta activa
	if (wasConnected && window.ethereum) {
		// La cuenta actual seleccionada
		const accounts = await window.ethereum.request({ method: "eth_accounts" });
		if (accounts.length > 0) {
			// Setear web3 y contrato sin pedir permiso otra vez
			web3 = new Web3(window.ethereum);
			swapContract = new web3.eth.Contract(SWAP_ABI, SWAP_CONTRACT_ADDRESS);
			isWalletConnected = true;
			document.getElementById("walletAddress").innerText = `Conectado: ${accounts[0]}`;
			document.getElementById("walletAction").innerText = "Desconectar Wallet";
		} else {
			// No hay cuentas autorizadas, limpiar flag
			sessionStorage.removeItem("walletConnected");
		}
	}
});
// --- Wallet Connection ---
async function connectWallet() {
	if (!window.ethereum) return showToast("Instalá MetaMask para usar la DApp.");
	web3 = new Web3(window.ethereum);
	await window.ethereum.request({ method: "eth_requestAccounts" });
	const accounts = await web3.eth.getAccounts();
	document.getElementById("walletAddress").innerText = `Conectado: ${accounts[0]}`;
	swapContract = new web3.eth.Contract(SWAP_ABI, SWAP_CONTRACT_ADDRESS);
	isWalletConnected = true;
	document.getElementById("walletAction").innerText = "Desconectar Wallet";
	populateTokenDropdowns();
	sessionStorage.setItem("walletConnected", "true");
}

function disconnectWallet() {
	web3 = null;
	swapContract = null;
	isWalletConnected = false;
	document.getElementById("walletAddress").innerText = "";
	document.getElementById("walletAction").innerText = "Conectar Wallet";
	showToast("Wallet desconectada 🔌");
	const balanceDisplay = document.getElementById("balanceInfo");
	if (balanceDisplay) balanceDisplay.innerHTML = "";
	sessionStorage.removeItem("walletConnected");
}

async function handleWalletAction() {
	if (!isWalletConnected) {
		await connectWallet();
	} else {
		disconnectWallet();
	}
}


// --- UI Section Management ---
function showSection(sectionKey, tabElement) {
	document.querySelectorAll("[id^='section-']").forEach(s => s.classList.add("d-none"));
	const section = document.getElementById(`section-${sectionKey}`);
	if (section) section.classList.remove("d-none");
	document.querySelectorAll("#mainTabs .nav-link").forEach(link => link.classList.remove("active"));
	if (tabElement) tabElement.classList.add("active");
	if (sectionKey === "add") {
		switchLiquidityMode("add");
		updateLiquidityPoolDisplay();
	}
}

// --- Token Dropdowns ---
function populateTokenDropdowns() {
	const selectIds = ["swapIn", "swapOut", "liqA", "liqB", "remA", "remB", "priceA", "priceB"];
	selectIds.forEach(id => {
		const select = document.getElementById(id);
		if (!select) return;
		select.innerHTML = "";
		TOKENS.forEach(token => {
			const option = document.createElement("option");
			option.value = token.address;
			option.text = `${token.icon} ${token.name}`;
			select.appendChild(option);
		});
	});
}

// --- Loader & Toasts ---
function toggleLoader(show) {
	document.getElementById("loader").classList.toggle("d-none", !show);
}

function showToast(message) {
	const toastId = `toast-${Date.now()}`;
	const html = `
    <div id="${toastId}" class="toast align-items-center text-white bg-dark mb-2" role="alert" aria-live="assertive" aria-atomic="true">
      <div class="d-flex">
        <div class="toast-body">${message}</div>
        <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
      </div>
    </div>
  `;
	const container = document.getElementById("toastContainer");
	container.insertAdjacentHTML("beforeend", html);
	new bootstrap.Toast(document.getElementById(toastId)).show();
}


// --- ERC20 Approval Helper ---
async function checkAndApproveERC20(tokenAddress, amountWei, userAddress) {
	const tokenContract = new web3.eth.Contract(ERC20_ABI, tokenAddress);
	const allowance = await tokenContract.methods.allowance(userAddress, SWAP_CONTRACT_ADDRESS).call();
	if (BigInt(allowance) >= BigInt(amountWei)) return;
	showToast(`Aprobando token ${getTokenSymbol(tokenAddress)}...`);
	await tokenContract.methods.approve(SWAP_CONTRACT_ADDRESS, amountWei).send({ from: userAddress });
	showToast(`Token ${getTokenSymbol(tokenAddress)} aprobado ✔️`);
}

/**
 * Ejecuta un swap de tokens usando swapContract.swapExactTokensForTokens
 */
async function swapTokens() {
	toggleLoader(true);

	try {
		// 1. Obtener cuenta conectada
		const [user] = await web3.eth.getAccounts();
		// 2. Leer inputs de UI
		const tokenIn = document.getElementById("swapIn").value;
		const tokenOut = document.getElementById("swapOut").value;
		const amountInRaw = document.getElementById("swapAmount").value.trim();
		// 3. Validaciones
		if (!tokenIn || !tokenOut || tokenIn === tokenOut || isNaN(amountInRaw) || Number(amountInRaw) <= 0) {
			showToast("Par de tokens inválido o cantidad vacía ❌");
			return;
		}
		// 4. Convertir a wei (string)
		const weiIn = web3.utils.toWei(amountInRaw, "ether");
		const weiInBig = BigInt(weiIn);
		// 5. Obtener reservas
		let { tokenAReserve: reserveIn, tokenBReserve: reserveOut } =
			await swapContract.methods.reserves(tokenIn, tokenOut).call();
		// 6. Verifica existencia de liquidez
		if (reserveIn === "0" || reserveOut === "0") {
			let reverse = await swapContract.methods.reserves(tokenOut, tokenIn).call();
			if (reverse.tokenAReserve !== "0" && reverse.tokenBReserve !== "0") {
				showToast("⚠️ Liquidez disponible, pero en orden inverso. Intercambiá los tokens.");
			} else {
				showToast("❌ No hay liquidez para este par.");
			}
			return;
		}
		// 7. Obtener output estimado
		let amountOutStr;
		try {
			// Aseguramos que las reservas estén en formato string válido
			const safeReserveIn = typeof reserveIn === "bigint" ? reserveIn.toString() : reserveIn;
			const safeReserveOut = typeof reserveOut === "bigint" ? reserveOut.toString() : reserveOut;

			amountOutStr = await swapContract.methods
				.getAmountOut(weiIn, safeReserveIn, safeReserveOut)
				.call();

		} catch (err) {
			showToast("No se pudo calcular la cantidad a recibir ❌");
			return;
		}

		// Validación del valor obtenido
		if (!amountOutStr || !/^\d+$/.test(amountOutStr)) {
			throw new Error("getAmountOut devolvió un valor inválido");
		}

		// 8. Slippage (99%)
		const amountOut = BigInt(amountOutStr);
		const amountOutMin = (amountOut * 99n) / 100n;
		const amountOutMinStr = amountOutMin.toString();

		// 9. Mostrar mínimo en la UI
		const swapMinOutEl = document.getElementById("swapMinOut");
		if (swapMinOutEl) {
			try {
				// Conversión segura: usá la tuya o la nativa
				swapMinOutEl.innerText = formatBigIntToDecimal(amountOutMin, 18, 6);
				// O si preferís mantener web3:
				// swapMinOutEl.innerText = web3.utils.fromWei(amountOutMinStr);
			} catch (e) {
				swapMinOutEl.innerText = "0.0";
			}
		}


		// 10. Aprobar tokenIn si es necesario
		await checkAndApproveERC20(tokenIn, weiIn, user);

		// 11. Ejecutar el swap
		const deadline = Math.floor(Date.now() / 1000) + 600; // 10 min
		const tx = await swapContract.methods
			.swapExactTokensForTokens(
				weiIn, // input
				amountOutMinStr, // slippage min
				[tokenIn, tokenOut],
				user,
				deadline
			)
			.send({ from: user });

		// 12. Actualizar UI
		showToast("Swap exitoso ✔️");

		let receivedAmount;
		try {
			const divisor = BigInt("1000000000000000000"); // 1e18
			const whole = amountOut / divisor;
			const decimal = (amountOut % divisor) * 100n / divisor; // 2 decimales
			receivedAmount = `${whole.toString()},${decimal.toString().padStart(2, "0")}`;

		} catch {
			receivedAmount = amountOutStr;
		}

		saveHistory(
			`Intercambiado ${amountInRaw} ${getTokenSymbol(tokenIn)} por ` +
			`${receivedAmount} ${getTokenSymbol(tokenOut)}`
		);
	} catch (err) {
		showToast("Error al hacer swap ❌ " + (err.message || "Error desconocido"));
	} finally {
		toggleLoader(false);
	}
}



// --- Agregar Liquidez ---
async function addLiquidity() {
	if (!isWalletConnected) return showToast("Conectá tu wallet primero.");
	toggleLoader(true);
	try {
		const [user] = await web3.eth.getAccounts();
		const tokenA = document.getElementById("liqA").value;
		const tokenB = document.getElementById("liqB").value;
		const amountADesired = document.getElementById("liqADesired").value;
		const amountBDesired = document.getElementById("liqBDesired").value;
		if (tokenA === tokenB) throw new Error("Los tokens para liquidez deben ser diferentes.");
		if (Number(amountADesired) <= 0 || Number(amountBDesired) <= 0) throw new Error("Cantidad deseada debe ser positiva.");
		const amountAMin = (Number(amountADesired) * 0.95).toFixed(6);
		const amountBMin = (Number(amountBDesired) * 0.95).toFixed(6);
		const amountADesiredWei = web3.utils.toWei(amountADesired, "ether");
		const amountBDesiredWei = web3.utils.toWei(amountBDesired, "ether");
		const amountAMinWei = web3.utils.toWei(amountAMin, "ether");
		const amountBMinWei = web3.utils.toWei(amountBMin, "ether");
		const deadline = 9999999999;
		await checkAndApproveERC20(tokenA, amountADesiredWei, user);
		await checkAndApproveERC20(tokenB, amountBDesiredWei, user);
		await swapContract.methods.addLiquidity(
			tokenA,
			tokenB,
			amountADesiredWei,
			amountBDesiredWei,
			amountAMinWei,
			amountBMinWei,
			user,
			deadline
		).send({ from: user });
		showToast("Liquidez agregada ✔️");
		clearAddLiquidityForm();
		await updateLiquidityPoolDisplay();
	} catch (err) {
		showToast("Error al agregar liquidez ❌ " + (err.message || ""));
	} finally {
		toggleLoader(false);
	}
}


// --- Remover Liquidez ---
async function removeLiquidity() {
	if (!isWalletConnected) {
		showToast("Conectá tu wallet primero.");
		return;
	}

	toggleLoader(true);

	try {
		const [user] = await web3.eth.getAccounts();
		const tokenA = document.getElementById("remA").value;
		const tokenB = document.getElementById("remB").value;
		const liquidityAmount = document.getElementById("remAmount").value.trim();

		if (tokenA === tokenB) {
			throw new Error("Los tokens deben ser diferentes.");
		}
		if (Number(liquidityAmount) <= 0) {
			throw new Error("Cantidad de liquidez debe ser positiva.");
		}

		// Convertir a wei
		const weiLiquidity = web3.utils.toWei(liquidityAmount, "ether");

		// Obtener reservas del pool
		const reserves = await swapContract.methods.reserves(tokenA, tokenB).call();

		// Extraer BigInt de reservas
		let rawReserveA = reserves.tokenAReserve ?? reserves["0"];
		let rawReserveB = reserves.tokenBReserve ?? reserves["1"];

		if (rawReserveA === undefined || rawReserveB === undefined) {
			throw new Error("Reservas no encontradas para este par.");
		}

		// Calcular totalLiquidity = reserveA + reserveB
		const totalLiquidity =
			BigInt(rawReserveA.toString()) + BigInt(rawReserveB.toString());

		// Calcular montos proporcionales
		const amountA =
			(BigInt(rawReserveA.toString()) * BigInt(weiLiquidity)) /
			totalLiquidity;
		const amountB =
			(BigInt(rawReserveB.toString()) * BigInt(weiLiquidity)) /
			totalLiquidity;

		// Slippage del 1%
		const minA = (amountA * 99n) / 100n;
		const minB = (amountB * 99n) / 100n;

		// Mostrar mínimos en la UI
		const minAInput = document.getElementById("remAMin");
		const minBInput = document.getElementById("remBMin");
		if (minAInput)
			minAInput.value = formatBigIntToDecimal(minA, 18, 6);
		if (minBInput)
			minBInput.value = formatBigIntToDecimal(minB, 18, 6);

		// Ejecutar transacción removeLiquidity
		const deadline = Math.floor(Date.now() / 1000) + 600; // +10 min
		await swapContract.methods
			.removeLiquidity(
				tokenA,
				tokenB,
				weiLiquidity,
				minA.toString(),
				minB.toString(),
				user,
				deadline
			)
			.send({ from: user });

		showToast("Liquidez removida ✔️");
		clearRemoveLiquidityForm();
		await updateLiquidityPoolDisplay();
	} catch (err) {
		showToast("Error al remover liquidez ❌ " + (err.message || ""));
	} finally {
		toggleLoader(false);
	}
}


// --- Formateo de BigInt a Decimal ---
function formatBigIntToDecimal(bigIntValue, decimals = 18, fixed = 4) {
	try {
		const divisor = BigInt("1" + "0".repeat(decimals));
		const whole = bigIntValue / divisor;
		const decimal = (bigIntValue % divisor) * BigInt(10 ** fixed) / divisor;
		return `${whole.toString()}.${decimal.toString().padStart(fixed, "0")}`;
	} catch {
		return "0.0";
	}
}

async function updateLiquidityPoolDisplay() {
	if (!swapContract) return;

	const tokenA = document.getElementById("liqA")?.value;
	const tokenB = document.getElementById("liqB")?.value;

	if (!tokenA || !tokenB || tokenA === tokenB) {
		document.getElementById("poolReserveA").innerText = "–";
		document.getElementById("poolReserveB").innerText = "–";
		return;
	}

	try {
		const reserves = await swapContract.methods.reserves(tokenA, tokenB).call();

		let rawReserveA = reserves.tokenAReserve ?? reserves["0"];
		let rawReserveB = reserves.tokenBReserve ?? reserves["1"];

		if (!rawReserveA || !rawReserveB || (rawReserveA === "0" && rawReserveB === "0")) {
			document.getElementById("poolReserveA").innerText = `0.0 ${getTokenSymbol(tokenA)}`;
			document.getElementById("poolReserveB").innerText = `0.0 ${getTokenSymbol(tokenB)}`;
			return;
		}

		const readableA = formatBigIntToDecimal(BigInt(rawReserveA), 18, 4);
		const readableB = formatBigIntToDecimal(BigInt(rawReserveB), 18, 4);

		document.getElementById("poolReserveA").innerText = `${readableA} ${getTokenSymbol(tokenA)}`;
		document.getElementById("poolReserveB").innerText = `${readableB} ${getTokenSymbol(tokenB)}`;
	} catch (err) {
		// Si el contrato no tiene reservas para este par, muestra 0.0
		document.getElementById("poolReserveA").innerText = `0.0 ${getTokenSymbol(tokenA)}`;
		document.getElementById("poolReserveB").innerText = `0.0 ${getTokenSymbol(tokenB)}`;
	}
	// Si no hay reservas, permite input manual en B
	if (rawReserveA === "0" && rawReserveB === "0") {
		document.getElementById("liqBDesired").disabled = false;
	} else {
		document.getElementById("liqBDesired").disabled = true;
	}

}


async function getPrice() {
	if (!isWalletConnected) return showToast("Conectá tu wallet primero.");
	try {
		const tokenA = document.getElementById("priceA").value;
		const tokenB = document.getElementById("priceB").value;
		if (tokenA === tokenB) throw new Error("Tokens deben ser diferentes.");
		const result = await swapContract.methods.getPrice(tokenA, tokenB).call();
		const readable = web3.utils.fromWei(result, "ether");
		document.getElementById("priceOutput").innerText = `1 ${getTokenSymbol(tokenA)} ≈ ${readable} ${getTokenSymbol(tokenB)}`;
		showToast("Precio consultado ✔️");
	} catch (err) {
		showToast("Error al consultar precio ❌ " + (err?.message || ""));
	}
}

// Limpieza de formularios
function clearAddLiquidityForm() {
	document.getElementById("liqADesired").value = "";
	document.getElementById("liqBDesired").value = "";
}

function clearRemoveLiquidityForm() {
	document.getElementById("remAmount").value = "";
	document.getElementById("remAMin").value = "";
	document.getElementById("remBMin").value = "";
}

// --- Utilidades ---
function getTokenSymbol(address) {
	const token = TOKENS.find(t => t.address.toLowerCase() === address.toLowerCase());
	return token ? token.name : address.slice(0, 6) + "...";
}

// --- Historial de Swaps ---
function saveHistory(text) {
	const old = JSON.parse(localStorage.getItem("swapHistory") || "[]");
	const updated = [...old, { text, time: new Date().toLocaleString() }];
	localStorage.setItem("swapHistory", JSON.stringify(updated));
	loadHistory();
}

function loadHistory() {
	const list = document.getElementById("historyList");
	if (!list) return;
	list.innerHTML = "";
	const history = JSON.parse(localStorage.getItem("swapHistory") || "[]").reverse();
	history.forEach(entry => {
		const item = document.createElement("li");
		item.className = "list-group-item";
		item.innerText = `${entry.time}: ${entry.text}`;
		list.appendChild(item);
	});
}
async function autofillBfromPrice() {
  const amountA = document.getElementById("liqADesired").value;
  const tokenA = document.getElementById("liqA").value;
  const tokenB = document.getElementById("liqB").value;
  if (!amountA || !tokenA || !tokenB || tokenA === tokenB) return;
  try {
    const price = await swapContract.methods.getPrice(tokenA, tokenB).call();
    const priceFloat = parseFloat(web3.utils.fromWei(price, "ether"));
    const amountB = (parseFloat(amountA) * priceFloat).toFixed(6);
    document.getElementById("liqBDesired").value = amountB;
  } catch (e) {
    showToast("No se pudo calcular el valor óptimo de B.");
    document.getElementById("liqBDesired").value = "";
  }
}
// --- Auto-cálculo dinámico de Amount B ---
document.addEventListener("DOMContentLoaded", () => {
  const amountAInput = document.getElementById("liqADesired");
  amountAInput?.addEventListener("input", async () => {
    await autofillBfromPrice();
  });
});
// Cambiar entre Add y Remove
function switchLiquidityMode(mode) {
	document.getElementById("addLiquidityForm").classList.toggle("d-none", mode !== "add");
	document.getElementById("removeLiquidityForm").classList.toggle("d-none", mode !== "remove");

	document.getElementById("tab-add").classList.toggle("active", mode === "add");
	document.getElementById("tab-remove").classList.toggle("active", mode === "remove");
}

document.addEventListener("DOMContentLoaded", () => {
	document.getElementById("liqA")?.addEventListener("change", updateLiquidityPoolDisplay);
	document.getElementById("liqB")?.addEventListener("change", updateLiquidityPoolDisplay);
});
