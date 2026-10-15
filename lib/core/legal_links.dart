// Legal links shown in Settings and next to the subscription (App Review 3.1.2).
//   flutter build ipa --dart-define=PRIVACY_POLICY_URL=https://...
const termsUrl = String.fromEnvironment(
  'TERMS_URL',
  defaultValue: 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
);
const privacyPolicyUrl = String.fromEnvironment('PRIVACY_POLICY_URL');
