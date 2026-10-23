class RegisterCustomerPayload {
  const RegisterCustomerPayload({
    required this.fullName,
    required this.emailAddress,
    required this.countryCode,
    required this.phoneNumber,
    required this.guestUUID,
    this.firebaseDeviceToken,
  });

  final String fullName;
  final String emailAddress;
  final String countryCode;
  final String phoneNumber;
  final String guestUUID;
  final String? firebaseDeviceToken;

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'emailAddress': emailAddress,
      'countryCode': countryCode,
      'phoneNumber': phoneNumber,
      if (guestUUID.trim().isNotEmpty) 'guestUUID': guestUUID,
      if (firebaseDeviceToken != null && firebaseDeviceToken!.trim().isNotEmpty)
        'firebaseDeviceToken': firebaseDeviceToken!.trim(),
    };
  }
}

class LoginWithEmailPayload {
  const LoginWithEmailPayload({
    required this.emailAddress,
    required this.guestUUID,
    this.firebaseDeviceToken,
  });

  final String emailAddress;
  final String guestUUID;
  final String? firebaseDeviceToken;

  Map<String, dynamic> toJson() => {
    'emailAddress': emailAddress,
    if (guestUUID.trim().isNotEmpty) 'guestUUID': guestUUID,
    if (firebaseDeviceToken != null && firebaseDeviceToken!.trim().isNotEmpty)
      'firebaseDeviceToken': firebaseDeviceToken!.trim(),
  };
}

class LoginWithPhonePayload {
  const LoginWithPhonePayload({
    required this.countryCode,
    required this.phoneNumber,
    required this.guestUUID,
    this.firebaseDeviceToken,
  });

  final String countryCode;
  final String phoneNumber;
  final String guestUUID;
  final String? firebaseDeviceToken;

  Map<String, dynamic> toJson() {
    return {
      'countryCode': countryCode,
      'phoneNumber': phoneNumber,
      if (guestUUID.trim().isNotEmpty) 'guestUUID': guestUUID,
      if (firebaseDeviceToken != null && firebaseDeviceToken!.trim().isNotEmpty)
        'firebaseDeviceToken': firebaseDeviceToken!.trim(),
    };
  }
}

class GoogleOauthPayload {
  const GoogleOauthPayload({
    required this.idToken,
    required this.guestUUID,
    this.firebaseDeviceToken,
  });

  final String idToken;
  final String guestUUID;
  final String? firebaseDeviceToken;

  Map<String, dynamic> toJson() => {
    'idToken': idToken,
    if (guestUUID.trim().isNotEmpty) 'guestUUID': guestUUID,
    if (firebaseDeviceToken != null && firebaseDeviceToken!.trim().isNotEmpty)
      'firebaseDeviceToken': firebaseDeviceToken!.trim(),
  };
}

class FacebookOauthPayload {
  const FacebookOauthPayload({
    required this.accessToken,
    required this.guestUUID,
    this.firebaseDeviceToken,
  });

  final String accessToken;
  final String guestUUID;
  final String? firebaseDeviceToken;

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    if (guestUUID.trim().isNotEmpty) 'guestUUID': guestUUID,
    if (firebaseDeviceToken != null && firebaseDeviceToken!.trim().isNotEmpty)
      'firebaseDeviceToken': firebaseDeviceToken!.trim(),
  };
}

class AppleOauthPayload {
  const AppleOauthPayload({
    required this.identityToken,
    required this.guestUUID,
    this.authorizationCode,
    this.fullName,
    this.firebaseDeviceToken,
  });

  final String identityToken;
  final String guestUUID;
  final String? authorizationCode;
  final String? fullName;
  final String? firebaseDeviceToken;

  Map<String, dynamic> toJson() {
    return {
      'identityToken': identityToken,
      if (guestUUID.trim().isNotEmpty) 'guestUUID': guestUUID,
      if (authorizationCode != null && authorizationCode!.trim().isNotEmpty)
        'authorizationCode': authorizationCode!.trim(),
      if (fullName != null && fullName!.trim().isNotEmpty)
        'fullName': fullName!.trim(),
      if (firebaseDeviceToken != null && firebaseDeviceToken!.trim().isNotEmpty)
        'firebaseDeviceToken': firebaseDeviceToken!.trim(),
    };
  }
}

class VerifyCustomerPayload {
  const VerifyCustomerPayload({
    required this.token,
    required this.secret,
    this.firebaseDeviceToken,
  });

  final String token;
  final String secret;
  final String? firebaseDeviceToken;

  Map<String, dynamic> toJson() => {
    'token': token,
    'secret': secret,
    if (firebaseDeviceToken != null && firebaseDeviceToken!.trim().isNotEmpty)
      'firebaseDeviceToken': firebaseDeviceToken!.trim(),
  };
}

class UpdateCustomerProfilePayload {
  const UpdateCustomerProfilePayload({required this.fullName});

  final String fullName;

  Map<String, dynamic> toJson() => {'fullName': fullName};
}

class UpdateCustomerEmailPayload {
  const UpdateCustomerEmailPayload({required this.emailAddress});

  final String emailAddress;

  Map<String, dynamic> toJson() => {'emailAddress': emailAddress};
}

class RegisterGuestPayload {
  const RegisterGuestPayload({required this.deviceId, required this.token});

  final String deviceId;
  final String token;

  Map<String, dynamic> toJson() => {'deviceId': deviceId, 'token': token};
}
