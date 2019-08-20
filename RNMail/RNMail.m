#import <MessageUI/MessageUI.h>
#import "RNMail.h"
#import <React/RCTConvert.h>
#import <React/RCTLog.h>

@implementation RNMail
{
    NSMutableDictionary *_callbacks;
}

- (instancetype)init
{
    if ((self = [super init])) {
        _callbacks = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
} 

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(mail:(NSDictionary *)options
                  callback: (RCTResponseSenderBlock)callback)
{
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
        mail.mailComposeDelegate = self;
        _callbacks[RCTKeyForInstance(mail)] = callback;

        if (options[@"subject"]){
            NSString *subject = [RCTConvert NSString:options[@"subject"]];
            [mail setSubject:subject];
        }

        bool *isHTML = NO;
        
        if (options[@"isHTML"]){
            isHTML = [options[@"isHTML"] boolValue];
        }

        if (options[@"body"]){
            NSString *body = [RCTConvert NSString:options[@"body"]];
            [mail setMessageBody:body isHTML:isHTML];
        }

        if (options[@"recipients"]){
            NSArray *recipients = [RCTConvert NSArray:options[@"recipients"]];
            [mail setToRecipients:recipients];
        }
        
        if (options[@"ccRecipients"]){
            NSArray *ccRecipients = [RCTConvert NSArray:options[@"ccRecipients"]];
            [mail setCcRecipients:ccRecipients];
        }
        
        if (options[@"bccRecipients"]){
            NSArray *bccRecipients = [RCTConvert NSArray:options[@"bccRecipients"]];
            [mail setBccRecipients:bccRecipients];
        }
        
        if (options[@"attachments"]){
            NSArray *attachments = [RCTConvert NSArray:options[@"attachments"]];

            for(NSDictionary *attachment in attachments) {
                if (attachment[@"path"] && attachment[@"type"]) {
                    NSString *attachmentUrlString = [RCTConvert NSString:attachment[@"path"]];
                    NSString *attachmentType = [RCTConvert NSString:attachment[@"type"]];
                    NSString *attachmentName = [RCTConvert NSString:attachment[@"name"]];
                    
                    // Set default filename if not specificed
                    if (!attachmentName) {
                        attachmentName = [[attachmentUrlString lastPathComponent] stringByDeletingPathExtension];
                    }
                    
                    NSURL *attachmentUrl = [[NSURLComponents componentsWithString:attachmentUrlString] URL];
                    // Get the resource path and read the file using NSData
                    NSData *fileData = [NSData dataWithContentsOfURL:attachmentUrl];
                    
                    // Determine the MIME type
                    NSString *mimeType;
                    
                    /*
                     * Add additional mime types and PR if necessary. Find the list
                     * of supported formats at http://www.iana.org/assignments/media-types/media-types.xhtml
                     */
                    if ([attachmentType containsString:@"jpeg"]) {
                        mimeType = @"image/jpeg";
                    } else if ([attachmentType containsString:@"png"]) {
                        mimeType = @"image/png";
                    } else if ([attachmentType containsString:@"doc"]) {
                        mimeType = @"application/msword";
                    } else if ([attachmentType containsString:@"docx"]) {
                        mimeType = @"application/vnd.openxmlformats-officedocument.wordprocessingml.document";
                    } else if ([attachmentType containsString:@"ppt"]) {
                        mimeType = @"application/vnd.ms-powerpoint";
                    } else if ([attachmentType containsString:@"pptx"]) {
                        mimeType = @"application/vnd.openxmlformats-officedocument.presentationml.presentation";
                    } else if ([attachmentType containsString:@"html"]) {
                        mimeType = @"text/html";
                    } else if ([attachmentType containsString:@"csv"]) {
                        mimeType = @"text/csv";
                    } else if ([attachmentType containsString:@"pdf"]) {
                        mimeType = @"application/pdf";
                    } else if ([attachmentType containsString:@"vcard"]) {
                        mimeType = @"text/vcard";
                    } else if ([attachmentType containsString:@"json"]) {
                        mimeType = @"application/json";
                    } else if ([attachmentType containsString:@"zip"]) {
                        mimeType = @"application/zip";
                    } else if ([attachmentType containsString:@"text"]) {
                        mimeType = @"text/*";
                    } else if ([attachmentType containsString:@"mp3"]) {
                        mimeType = @"audio/mpeg";
                    } else if ([attachmentType containsString:@"wav"]) {
                        mimeType = @"audio/wav";
                    } else if ([attachmentType containsString:@"aiff"]) {
                        mimeType = @"audio/aiff";
                    } else if ([attachmentType containsString:@"flac"]) {
                        mimeType = @"audio/flac";
                    } else if ([attachmentType containsString:@"ogg"]) {
                        mimeType = @"audio/ogg";
                    } else if ([attachmentType containsString:@"xls"]) {
                        mimeType = @"application/vnd.ms-excel";
                    } else if ([attachmentType containsString:@"ics"]) {
                        mimeType = @"text/calendar";
                    } else if ([attachmentType containsString:@"xlsx"]) {
                        mimeType = @"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
                    }
                    [mail addAttachmentData:fileData mimeType:mimeType fileName:attachmentName];
                }
            }
        }
        
        UIViewController *root = [[[[UIApplication sharedApplication] delegate] window] rootViewController];

        while (root.presentedViewController) {
            root = root.presentedViewController;
        }
        [root presentViewController:mail animated:YES completion:nil];
    } else {
        callback(@[@"not_available"]);
    }
}

#pragma mark MFMailComposeViewControllerDelegate Methods

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    NSString *key = RCTKeyForInstance(controller);
    RCTResponseSenderBlock callback = _callbacks[key];
    if (callback) {
        switch (result) {
            case MFMailComposeResultSent:
                callback(@[[NSNull null] , @"sent"]);
                break;
            case MFMailComposeResultSaved:
                callback(@[[NSNull null] , @"saved"]);
                break;
            case MFMailComposeResultCancelled:
                callback(@[[NSNull null] , @"cancelled"]);
                break;
            case MFMailComposeResultFailed:
                callback(@[@"failed"]);
                break;
            default:
                callback(@[@"error"]);
                break;
        }
        [_callbacks removeObjectForKey:key];
    } else {
        RCTLogWarn(@"No callback registered for mail: %@", controller.title);
    }
    UIViewController *ctrl = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    while (ctrl.presentedViewController && ctrl != controller) {
        ctrl = ctrl.presentedViewController;
    }
    [ctrl dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Private

static NSString *RCTKeyForInstance(id instance)
{
    return [NSString stringWithFormat:@"%p", instance];
}

@end
