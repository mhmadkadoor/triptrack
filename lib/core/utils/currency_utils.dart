String getCurrencySymbol(String currencyCode) {
  switch (currencyCode.toUpperCase()) {
    case 'TRY':
      return '₺';
    case 'EUR':
      return '€';
    case 'GBP':
      return '£';
    case 'USD':
      return '\$';
    default:
      return '\$';
  }
}
