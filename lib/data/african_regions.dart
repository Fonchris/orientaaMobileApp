/// Maps ISO country codes to African regions.
/// Used by the country picker to group African countries.
class AfricanRegions {
  static const Map<String, String> regionByCode = {
    // West Africa
    'NG': 'West Africa',
    'GH': 'West Africa',
    'CI': 'West Africa',
    'SN': 'West Africa',
    'BJ': 'West Africa',
    'TG': 'West Africa',
    'NE': 'West Africa',
    'ML': 'West Africa',
    'BF': 'West Africa',
    'GN': 'West Africa',
    'GW': 'West Africa',
    'LR': 'West Africa',
    'SL': 'West Africa',
    'GM': 'West Africa',
    'CV': 'West Africa',
    'MR': 'West Africa',

    // East Africa
    'KE': 'East Africa',
    'TZ': 'East Africa',
    'UG': 'East Africa',
    'ET': 'East Africa',
    'RW': 'East Africa',
    'SO': 'East Africa',
    'SS': 'East Africa',
    'SD': 'East Africa',
    'DJ': 'East Africa',
    'ER': 'East Africa',
    'BI': 'East Africa',
    'KM': 'East Africa',
    'SC': 'East Africa',
    'MU': 'East Africa',
    'MG': 'East Africa',
    'MW': 'East Africa',
    'ZM': 'East Africa',
    'ZW': 'East Africa',

    // Central Africa
    'CD': 'Central Africa',
    'CM': 'Central Africa',
    'AO': 'Central Africa',
    'TD': 'Central Africa',
    'CF': 'Central Africa',
    'CG': 'Central Africa',
    'GA': 'Central Africa',
    'GQ': 'Central Africa',
    'ST': 'Central Africa',

    // Southern Africa
    'ZA': 'Southern Africa',
    'BW': 'Southern Africa',
    'NA': 'Southern Africa',
    'MZ': 'Southern Africa',
    'LS': 'Southern Africa',
    'SZ': 'Southern Africa',

    // North Africa
    'EG': 'North Africa',
    'MA': 'North Africa',
    'DZ': 'North Africa',
    'TN': 'North Africa',
    'LY': 'North Africa',
    'EH': 'North Africa',
  };

  /// Returns the region name for a given ISO country code, or null if not an African country.
  static String? getRegion(String countryCode) {
    return regionByCode[countryCode.toUpperCase()];
  }

  /// Returns true if the country code is an African country.
  static bool isAfrican(String countryCode) {
    return regionByCode.containsKey(countryCode.toUpperCase());
  }
}