#import "TikTokBusinessIntegration.h"

#import <TikTokBusinessSDK/TikTokBusinessSDK.h>

void TTInitializeTikTokBusinessSDK(void) {
  NSString *appId = @"6758658533";
  NSString *tiktokAppId = @"7649588961605648404";

  TikTokConfig *config = [[TikTokConfig alloc] initWithAppId:appId tiktokAppId:tiktokAppId];
  if (config == nil) {
    NSLog(@"TikTokBusiness config creation failed");
    return;
  }

  [TikTokBusiness initializeSdk:config completionHandler:^(BOOL success, NSError * _Nullable error) {
    if (!success && error != nil) {
      NSLog(@"TikTokBusiness init failed: %@", error.localizedDescription);
    }
  }];
}

static NSString *TTCanonicalBaseEventName(NSString *eventName) {
  if ([eventName isEqualToString:@"add_payment_info"]) return TTEventNameAddPaymentInfo;
  if ([eventName isEqualToString:@"generate_lead"]) return TTEventNameGenerateLead;
  if ([eventName isEqualToString:@"launch_app"]) return TTEventNameLaunchAPP;
  if ([eventName isEqualToString:@"login"]) return TTEventNameLogin;
  if ([eventName isEqualToString:@"rate"]) return TTEventNameRate;
  return eventName;
}

void TTTrackTikTokIdentify(NSString * _Nullable externalID,
                           NSString * _Nullable externalUserName,
                           NSString * _Nullable phoneNumber,
                           NSString * _Nullable email) {
  [TikTokBusiness identifyWithExternalID:externalID
                       externalUserName:externalUserName
                            phoneNumber:phoneNumber
                                  email:email];
}

void TTTrackTikTokBaseEvent(NSString *eventName, NSString * _Nullable eventId) {
  NSString *canonicalEventName = TTCanonicalBaseEventName(eventName);
  TikTokBaseEvent *event = eventId.length > 0
      ? [[TikTokBaseEvent alloc] initWithEventName:canonicalEventName eventId:eventId]
      : [[TikTokBaseEvent alloc] initWithEventName:canonicalEventName];
  [TikTokBusiness trackTTEvent:event];
}

static NSArray<TikTokContentParams *> *TTContentParamsArrayFromDictionaries(NSArray *contents) {
  NSMutableArray<TikTokContentParams *> *result = [NSMutableArray array];

  for (id item in contents) {
    if (![item isKindOfClass:[NSDictionary class]]) {
      continue;
    }

    NSDictionary *contentDict = (NSDictionary *)item;
    TikTokContentParams *content = [[TikTokContentParams alloc] init];
    if ([contentDict[@"price"] respondsToSelector:@selector(doubleValue)]) {
      content.price = @([contentDict[@"price"] doubleValue]);
    }
    if ([contentDict[@"quantity"] respondsToSelector:@selector(integerValue)]) {
      content.quantity = [contentDict[@"quantity"] integerValue];
    }
    if ([contentDict[@"contentId"] isKindOfClass:[NSString class]]) {
      content.contentId = contentDict[@"contentId"];
    }
    if ([contentDict[@"contentCategory"] isKindOfClass:[NSString class]]) {
      content.contentCategory = contentDict[@"contentCategory"];
    }
    if ([contentDict[@"contentName"] isKindOfClass:[NSString class]]) {
      content.contentName = contentDict[@"contentName"];
    }
    if ([contentDict[@"brand"] isKindOfClass:[NSString class]]) {
      content.brand = contentDict[@"brand"];
    }

    [result addObject:content];
  }

  return result.copy;
}

static void TTConfigureContentEvent(TikTokContentsEvent *event, NSDictionary *properties) {
  NSString *contentId = [properties[@"contentId"] isKindOfClass:[NSString class]] ? properties[@"contentId"] : nil;
  NSString *descriptionText = [properties[@"description"] isKindOfClass:[NSString class]] ? properties[@"description"] : nil;
  NSString *contentType = [properties[@"contentType"] isKindOfClass:[NSString class]] ? properties[@"contentType"] : nil;
  NSString *value = [properties[@"value"] isKindOfClass:[NSString class]] ? properties[@"value"] : nil;
  NSString *currency = [properties[@"currency"] isKindOfClass:[NSString class]] ? properties[@"currency"] : nil;
  NSArray *contents = [properties[@"contents"] isKindOfClass:[NSArray class]] ? properties[@"contents"] : nil;

  if (contentId) {
    [event setContentId:contentId];
  }
  if (descriptionText) {
    [event setDescription:descriptionText];
  }
  if (contentType) {
    [event setContentType:contentType];
  }
  if (value) {
    [event setValue:value];
  }
  if (currency) {
    [event setCurrency:currency];
  }
  if (contents.count > 0) {
    [event setContents:TTContentParamsArrayFromDictionaries(contents)];
  }
}

void TTTrackTikTokContentsEvent(NSString *eventType,
                                NSDictionary * _Nullable properties,
                                NSString * _Nullable eventId) {
  NSDictionary *safeProperties = [properties isKindOfClass:[NSDictionary class]] ? properties : @{};

  TikTokContentsEvent *event = nil;
  if ([eventType isEqualToString:@"add_to_cart"]) {
    event = eventId.length > 0 ? [[TikTokAddToCartEvent alloc] initWithEventId:eventId] : [[TikTokAddToCartEvent alloc] initWithEventId:@""];
  } else if ([eventType isEqualToString:@"add_to_wishlist"]) {
    event = eventId.length > 0 ? [[TikTokAddToWishlistEvent alloc] initWithEventId:eventId] : [[TikTokAddToWishlistEvent alloc] initWithEventId:@""];
  } else if ([eventType isEqualToString:@"checkout"]) {
    event = eventId.length > 0 ? [[TikTokCheckoutEvent alloc] initWithEventId:eventId] : [[TikTokCheckoutEvent alloc] initWithEventId:@""];
  } else if ([eventType isEqualToString:@"view_content"]) {
    event = eventId.length > 0 ? [[TikTokViewContentEvent alloc] initWithEventId:eventId] : [[TikTokViewContentEvent alloc] initWithEventId:@""];
  } else if ([eventType isEqualToString:@"purchase"]) {
    event = eventId.length > 0 ? [[TikTokPurchaseEvent alloc] initWithEventId:eventId] : [[TikTokPurchaseEvent alloc] initWithEventId:@""];
  }

  if (event == nil) {
    NSLog(@"TikTokBusiness unsupported contents event type: %@", eventType);
    return;
  }

  TTConfigureContentEvent(event, safeProperties);
  [TikTokBusiness trackTTEvent:event];
}
