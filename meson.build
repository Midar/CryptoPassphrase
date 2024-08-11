project('CryptoPassphrase', 'objc',
  version: '1.0.1',
  meson_version: '>= 1.5.0')

objfw_dep = dependency('objfw')

executable('cryptopassphrase',
  [
    'CryptoPassphrase.m',
    'LegacyPasswordGenerator.m',
    'NewPasswordGenerator.m'
  ],
  dependencies: [objfw_dep],
  pie: true,
  install: true)
