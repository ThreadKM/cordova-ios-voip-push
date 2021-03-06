#import "VoIPPushNotification.h"
#import <Cordova/CDV.h>

@implementation VoIPPushNotification

@synthesize VoIPPushCallbackId;

- (void)init:(CDVInvokedUrlCommand*)command
{
  self.VoIPPushCallbackId = command.callbackId;
  NSLog(@"[objC] callbackId: %@", self.VoIPPushCallbackId);

  //http://stackoverflow.com/questions/27245808/implement-pushkit-and-test-in-development-behavior/28562124#28562124
  PKPushRegistry *pushRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
  pushRegistry.delegate = self;
  pushRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type{
    if([credentials.token length] == 0) {
        NSLog(@"[objC] No device token!");
        return;
    }

    //http://stackoverflow.com/a/9372848/534755
    NSLog(@"[objC] Device token: %@", credentials.token);
    const unsigned *tokenBytes = [credentials.token bytes];
    NSString *sToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                         ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                         ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                         ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];

    NSMutableDictionary* results = [NSMutableDictionary dictionaryWithCapacity:2];
    [results setObject:sToken forKey:@"deviceToken"];
    [results setObject:@"true" forKey:@"registration"];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:results];
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]]; //[pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.VoIPPushCallbackId];
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type
{
    NSDictionary *apsDict = payload.dictionaryPayload[@"aps"];
    NSDictionary *payloadDict = payload.dictionaryPayload;
    NSLog(@"[objC] didReceiveIncomingPushWithPayload: %@", payloadDict);

    NSString *message = apsDict[@"alert"];
    NSString *notId = payloadDict[@"notId"];
    NSString *contentAvailable = apsDict[@"content-available"];
    NSString *url = payloadDict[@"url"];
    NSLog(@"[objC] received VoIP msg: %@", message);

    NSMutableDictionary* results = [NSMutableDictionary dictionaryWithCapacity:4];
    [results setObject:message forKey:@"alert"];
    [results setObject:notId forKey:@"notId"];
    [results setObject:contentAvailable forKey:@"content-available"];
    [results setObject:url forKey:@"url"];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:results];
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.VoIPPushCallbackId];
}

@end
