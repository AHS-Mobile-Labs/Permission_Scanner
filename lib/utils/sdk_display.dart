class SdkDisplay {
  static const Map<int, String> _androidNames = {
    21: '5.0 Lollipop',
    22: '5.1 Lollipop',
    23: '6.0 Marshmallow',
    24: '7.0 Nougat',
    25: '7.1 Nougat',
    26: '8.0 Oreo',
    27: '8.1 Oreo',
    28: '9 Pie',
    29: '10',
    30: '11',
    31: '12',
    32: '12L',
    33: '13',
    34: '14',
    35: '15',
    36: '16',
  };

  static String apiValue(int api, {String codename = ''}) {
    if (api <= 0) return 'Unknown';
    final androidName = _androidNames[api];
    final suffix = _codenameSuffix(codename);
    if (androidName == null) return 'API $api$suffix';
    return 'API $api · Android $androidName$suffix';
  }

  static String compactApiValue(int api) {
    if (api <= 0) return 'Unknown';
    return 'API $api';
  }

  static String targetPosture(int targetApi) {
    if (targetApi <= 0) return 'Unknown target';
    if (targetApi >= 35) return 'Modern target';
    if (targetApi >= 33) return 'Recent target';
    if (targetApi >= 29) return 'Older target';
    return 'Legacy target';
  }

  static String targetNote(int targetApi) {
    if (targetApi <= 0) {
      return 'Target API was not exposed by Android package metadata.';
    }
    if (targetApi >= 35) {
      return 'Built for modern Android privacy and background limits.';
    }
    if (targetApi >= 33) {
      return 'Targets recent Android behavior, including newer notification and media rules.';
    }
    if (targetApi >= 29) {
      return 'Targets older Android behavior; review sensitive and background access carefully.';
    }
    return 'Targets legacy Android behavior and may receive compatibility exceptions.';
  }

  static String minNote(int minApi) {
    if (minApi <= 0) return 'Minimum supported Android version unavailable.';
    return 'Runs on ${apiValue(minApi)} and newer.';
  }

  static String compileValue(int compileApi, String codename) {
    if (compileApi <= 0 && codename.trim().isEmpty) return 'Unavailable';
    if (compileApi <= 0) return codename.trim();
    return apiValue(compileApi, codename: codename);
  }

  static String _codenameSuffix(String codename) {
    final clean = codename.trim();
    if (clean.isEmpty || clean == 'REL') return '';
    return ' ($clean)';
  }
}
