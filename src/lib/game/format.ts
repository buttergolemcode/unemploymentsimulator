// Formatting helpers

export function formatMoney(n: number): string {
  const neg = n < 0;
  const abs = Math.abs(n);
  let str: string;
  if (abs >= 1_000_000) {
    str = `$${(abs / 1_000_000).toFixed(2)}M`;
  } else if (abs >= 10_000) {
    str = `$${(abs / 1000).toFixed(1)}k`;
  } else {
    str = `$${abs.toLocaleString('en-US', { maximumFractionDigits: 0 })}`;
  }
  return neg ? `-${str}` : str;
}

export function formatMoneyFull(n: number): string {
  const neg = n < 0;
  return `${neg ? '-' : ''}$${Math.abs(n).toLocaleString('en-US', { maximumFractionDigits: 0 })}`;
}
