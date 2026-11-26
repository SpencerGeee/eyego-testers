// Seeds an approved driver with a vehicle (onboarding is out of scope), so
// the agent signs in on the driver phone and lands ready to go online.
// The rider signs up in the app itself. Same calls as EyeGo's scripts/e2e/lib.mjs.
const API = 'http://localhost:5020/v1';
const DRIVER_PHONE = '+233240000001'; // the app sends +233… (a bare 233… is a different account)

async function call(method, path, body, token) {
  const res = await fetch(API + path, {
    method,
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: body && JSON.stringify(body),
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(`${method} ${path} -> ${res.status} ${JSON.stringify(json).slice(0, 200)}`);
  return json.data ?? json;
}

const { _dev_otp: otp } = await call('POST', '/auth/driver/request-otp', { phone: DRIVER_PHONE });
const { accessToken } = await call('POST', '/auth/driver/verify-otp', { phone: DRIVER_PHONE, otp });
await call('POST', '/driver/verify', {
  name: 'Kwame Mensah',
  ghanaCardNumber: 'GHA-712345678-9',
  vehicle: { make: 'Toyota', model: 'HiAce', year: 2020, colour: 'White', plateNumber: 'GT-4821-24', seaterCount: 14, tier: 'ECO' },
}, accessToken);
await call('POST', '/driver/dev-activate', {}, accessToken);
// Cash rides need the commission float in the wallet, or every accept is a 402
// and the run burns 30+ min on re-offers (run 45838978641 finding #2).
// PAYMENT_PROVIDER=mock auto-accepts MoMo. Non-fatal: the agent can top up by hand.
try {
  await call('POST', '/driver/wallet/topup', { amountPesewas: 20000, method: 'MOMO_MTN' }, accessToken);
  const bal = await call('GET', '/driver/wallet/balance', null, accessToken);
  console.log('Seed driver wallet:', JSON.stringify(bal).slice(0, 120));
} catch (e) {
  console.log('Seed driver top-up failed (agent must top up in-app):', e.message);
}
console.log(`Seeded ACTIVE driver ${DRIVER_PHONE}`);
