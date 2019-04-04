#import <version.h>
#import "dump.h"

// Minimal Cydia Substrate header
typedef const void *MSImageRef;
MSImageRef MSGetImageByName(const char *file);
void *MSFindSymbol(MSImageRef image, const char *name);
void MSHookFunction(void *symbol, void *replace, void **result);

#define DPKG_PATH "/var/lib/dpkg/info/us.diatr.appsyncunified.list"

#ifdef DEBUG
	#define LOG(LogContents, ...) NSLog((@"AppSync Unified: %s:%d " LogContents), __FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
	#define LOG(...)
#endif

#define DECL_FUNC(name, ret, ...) \
	static ret (*original_ ## name)(__VA_ARGS__); \
	ret custom_ ## name(__VA_ARGS__)
#define HOOK_FUNC(name, image) do { \
	void *_ ## name = MSFindSymbol(image, "_" #name); \
	if (_ ## name == NULL) { \
		LOG(@"Failed to load symbol: " #name "."); \
		return; \
	} \
	MSHookFunction(_ ## name, (void *) custom_ ## name, (void **) &original_ ## name); \
} while(0)
#define LOAD_IMAGE(image, path) do { \
	image = MSGetImageByName(path); \
	if (image == NULL) { \
		LOG(@"Failed to load image: " #image "."); \
		return; \
	} \
} while (0)

#define kSecMagicBytesLength 2
static const uint8_t kSecMagicBytes[kSecMagicBytesLength] = {0xa1, 0x13};
#define kSecSubjectCStr "Apple iPhone OS Application Signing"

// TODO: Extract the "Apple iPhone OS Application Signing" intermediate certificate from an installed app on the device at runtime instead of including it in the code
#define kSecAppleCertificateLength 903
static const uint8_t kSecAppleCertificate[kSecAppleCertificateLength] = {0x30, 0x82, 0x03, 0x83, 0x30, 0x82, 0x02, 0x6B, 0xA0, 0x03, 0x02, 0x01, 0x02, 0x02, 0x01, 0x1E, 0x30, 0x0D, 0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x05, 0x05, 0x00, 0x30, 0x79, 0x31, 0x0B, 0x30, 0x09, 0x06, 0x03, 0x55, 0x04, 0x06, 0x13, 0x02, 0x55, 0x53, 0x31, 0x13, 0x30, 0x11, 0x06, 0x03, 0x55, 0x04, 0x0A, 0x13, 0x0A, 0x41, 0x70, 0x70, 0x6C, 0x65, 0x20, 0x49, 0x6E, 0x63, 0x2E, 0x31, 0x26, 0x30, 0x24, 0x06, 0x03, 0x55, 0x04, 0x0B, 0x13, 0x1D, 0x41, 0x70, 0x70, 0x6C, 0x65, 0x20, 0x43, 0x65, 0x72, 0x74, 0x69, 0x66, 0x69, 0x63, 0x61, 0x74, 0x69, 0x6F, 0x6E, 0x20, 0x41, 0x75, 0x74, 0x68, 0x6F, 0x72, 0x69, 0x74, 0x79, 0x31, 0x2D, 0x30, 0x2B, 0x06, 0x03, 0x55, 0x04, 0x03, 0x13, 0x24, 0x41, 0x70, 0x70, 0x6C, 0x65, 0x20, 0x69, 0x50, 0x68, 0x6F, 0x6E, 0x65, 0x20, 0x43, 0x65, 0x72, 0x74, 0x69, 0x66, 0x69, 0x63, 0x61, 0x74, 0x69, 0x6F, 0x6E, 0x20, 0x41, 0x75, 0x74, 0x68, 0x6F, 0x72, 0x69, 0x74, 0x79, 0x30, 0x1E, 0x17, 0x0D, 0x30, 0x38, 0x30, 0x35, 0x32, 0x31, 0x30, 0x32, 0x30, 0x34, 0x31, 0x35, 0x5A, 0x17, 0x0D, 0x32, 0x30, 0x30, 0x35, 0x32, 0x31, 0x30, 0x32, 0x30, 0x34, 0x31, 0x35, 0x5A, 0x30, 0x50, 0x31, 0x0B, 0x30, 0x09, 0x06, 0x03, 0x55, 0x04, 0x06, 0x13, 0x02, 0x55, 0x53, 0x31, 0x13, 0x30, 0x11, 0x06, 0x03, 0x55, 0x04, 0x0A, 0x13, 0x0A, 0x41, 0x70, 0x70, 0x6C, 0x65, 0x20, 0x49, 0x6E, 0x63, 0x2E, 0x31, 0x2C, 0x30, 0x2A, 0x06, 0x03, 0x55, 0x04, 0x03, 0x13, 0x23, 0x41, 0x70, 0x70, 0x6C, 0x65, 0x20, 0x69, 0x50, 0x68, 0x6F, 0x6E, 0x65, 0x20, 0x4F, 0x53, 0x20, 0x41, 0x70, 0x70, 0x6C, 0x69, 0x63, 0x61, 0x74, 0x69, 0x6F, 0x6E, 0x20, 0x53, 0x69, 0x67, 0x6E, 0x69, 0x6E, 0x67, 0x30, 0x81, 0x9F, 0x30, 0x0D, 0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x81, 0x8D, 0x00, 0x30, 0x81, 0x89, 0x02, 0x81, 0x81, 0x00, 0xB1, 0x1D, 0x55, 0x38, 0xAE, 0xEF, 0xF6, 0x30, 0xA5, 0x9B, 0x65, 0xAE, 0x79, 0x36, 0x01, 0x4D, 0x48, 0x02, 0x6E, 0x71, 0xB8, 0x67, 0xD2, 0xF8, 0x53, 0xF5, 0xD8, 0xB9, 0x27, 0xBD, 0xAD, 0x4B, 0xF7, 0x44, 0xF3, 0x5D, 0xD6, 0x83, 0x62, 0x31, 0x71, 0x20, 0x1D, 0xBE, 0x02, 0x91, 0x11, 0x42, 0xED, 0xD9, 0xCC, 0x29, 0xD8, 0x31, 0xE8, 0x60, 0x07, 0x1B, 0x07, 0x97, 0x74, 0x7F, 0xFA, 0x1D, 0x89, 0xDE, 0x85, 0x4B, 0xD5, 0x1F, 0xA4, 0xFE, 0x28, 0x2D, 0xD3, 0x29, 0x6E, 0xD4, 0x3F, 0xEB, 0x10, 0x99, 0x33, 0x11, 0x8C, 0xD4, 0xD4, 0x32, 0x15, 0xEE, 0xDF, 0xB3, 0x58, 0x2C, 0x29, 0x6C, 0x79, 0x48, 0x41, 0xAE, 0x0C, 0xDF, 0xE6, 0x8A, 0x2C, 0x2B, 0xA5, 0xE9, 0x1E, 0xD8, 0xB6, 0x71, 0xA2, 0xAB, 0x11, 0x28, 0x48, 0x72, 0xC5, 0xE3, 0x35, 0xA5, 0x0C, 0xDF, 0xE7, 0xAC, 0x44, 0x87, 0x02, 0x03, 0x01, 0x00, 0x01, 0xA3, 0x81, 0xC2, 0x30, 0x81, 0xBF, 0x30, 0x0B, 0x06, 0x03, 0x55, 0x1D, 0x0F, 0x04, 0x04, 0x03, 0x02, 0x07, 0x80, 0x30, 0x0C, 0x06, 0x03, 0x55, 0x1D, 0x13, 0x01, 0x01, 0xFF, 0x04, 0x02, 0x30, 0x00, 0x30, 0x16, 0x06, 0x03, 0x55, 0x1D, 0x25, 0x01, 0x01, 0xFF, 0x04, 0x0C, 0x30, 0x0A, 0x06, 0x08, 0x2B, 0x06, 0x01, 0x05, 0x05, 0x07, 0x03, 0x03, 0x30, 0x10, 0x06, 0x0A, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x63, 0x64, 0x06, 0x01, 0x03, 0x04, 0x02, 0x05, 0x00, 0x30, 0x1D, 0x06, 0x03, 0x55, 0x1D, 0x0E, 0x04, 0x16, 0x04, 0x14, 0x29, 0x74, 0x91, 0xAC, 0x21, 0xD9, 0xCD, 0xA4, 0xBD, 0x78, 0xF0, 0x8A, 0x46, 0xF9, 0x0A, 0xB4, 0x6E, 0x06, 0xAC, 0x09, 0x30, 0x1F, 0x06, 0x03, 0x55, 0x1D, 0x23, 0x04, 0x18, 0x30, 0x16, 0x80, 0x14, 0xE7, 0x34, 0x2A, 0x2E, 0x22, 0xDE, 0x39, 0x60, 0x6B, 0xB4, 0x94, 0xCE, 0x77, 0x83, 0x61, 0x2F, 0x31, 0xA0, 0x7C, 0x35, 0x30, 0x38, 0x06, 0x03, 0x55, 0x1D, 0x1F, 0x04, 0x31, 0x30, 0x2F, 0x30, 0x2D, 0xA0, 0x2B, 0xA0, 0x29, 0x86, 0x27, 0x68, 0x74, 0x74, 0x70, 0x3A, 0x2F, 0x2F, 0x77, 0x77, 0x77, 0x2E, 0x61, 0x70, 0x70, 0x6C, 0x65, 0x2E, 0x63, 0x6F, 0x6D, 0x2F, 0x61, 0x70, 0x70, 0x6C, 0x65, 0x63, 0x61, 0x2F, 0x69, 0x70, 0x68, 0x6F, 0x6E, 0x65, 0x2E, 0x63, 0x72, 0x6C, 0x30, 0x0D, 0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x05, 0x05, 0x00, 0x03, 0x82, 0x01, 0x01, 0x00, 0x8C, 0xEC, 0xB5, 0x3E, 0x50, 0x80, 0xCC, 0x0D, 0xF5, 0x1D, 0x2A, 0x24, 0x38, 0x1D, 0x60, 0xED, 0x32, 0x8E, 0xB2, 0x78, 0xBB, 0x73, 0x97, 0xF5, 0x90, 0x61, 0x4C, 0x35, 0xF2, 0x95, 0xDA, 0xB7, 0x97, 0xD3, 0x75, 0x4C, 0x05, 0xBE, 0xEE, 0xE3, 0xD1, 0x66, 0xF2, 0x36, 0xE8, 0xF1, 0xAD, 0x60, 0xDF, 0x92, 0x48, 0x6C, 0xD1, 0xC3, 0x95, 0x57, 0x22, 0x1F, 0xDC, 0x74, 0x3B, 0x36, 0xD6, 0xC9, 0x49, 0x43, 0xD0, 0x74, 0x9B, 0x74, 0xF3, 0xFD, 0xC8, 0x8E, 0x07, 0x79, 0x7B, 0x5C, 0xE0, 0x4B, 0x74, 0xB2, 0xBE, 0x05, 0xFE, 0x43, 0x68, 0xA2, 0x30, 0x04, 0xCC, 0x5B, 0x4B, 0x78, 0xB3, 0x08, 0x26, 0x3B, 0x28, 0x47, 0xCE, 0xF6, 0x59, 0xAB, 0xCC, 0x10, 0xE1, 0xBB, 0x55, 0x3C, 0x67, 0x55, 0x73, 0x98, 0xF2, 0x6E, 0xFE, 0x51, 0x80, 0xE7, 0x71, 0x54, 0xAF, 0x88, 0xE8, 0xDB, 0xE9, 0x73, 0xA9, 0x66, 0x17, 0x79, 0x70, 0x1B, 0x1C, 0xAB, 0x24, 0x74, 0x08, 0x20, 0x46, 0xC5, 0x99, 0x30, 0x3E, 0x13, 0x9A, 0x60, 0x9F, 0x08, 0x5B, 0xCC, 0x01, 0x26, 0xFA, 0x93, 0x6B, 0x72, 0xC7, 0xB6, 0xEC, 0x7E, 0x3B, 0x77, 0xE3, 0xEB, 0x85, 0x53, 0x82, 0x4B, 0xF7, 0x11, 0xF7, 0x5F, 0x7F, 0x1D, 0xDA, 0xA7, 0xFE, 0x24, 0xF5, 0x41, 0x7D, 0x10, 0xF1, 0xBF, 0xA6, 0x90, 0x86, 0xC8, 0x59, 0x98, 0xAF, 0x41, 0xFA, 0x91, 0x24, 0x7C, 0x2C, 0x38, 0x40, 0x97, 0xA2, 0xE8, 0x4F, 0x7A, 0xCD, 0x1A, 0xAD, 0x6F, 0xC0, 0x12, 0x1D, 0xA7, 0x59, 0xE5, 0xF5, 0x27, 0xF2, 0x00, 0x5C, 0xF0, 0xB6, 0x8F, 0x0E, 0xFB, 0xCE, 0x69, 0xAA, 0x1F, 0x21, 0x6A, 0xD8, 0xC7, 0x79, 0x1B, 0x4F, 0x1A, 0xB2, 0xC6, 0xC5, 0x9C, 0xEF, 0x11, 0x3E, 0x7B, 0xB1, 0xB7, 0x7E, 0xE8, 0x8C, 0xE0, 0xD1, 0xFE, 0x6D, 0x32};

static void copyIdentifierAndEntitlements(NSString *path, NSString **identifier, NSDictionary **info) {
	if (path == nil || identifier == NULL || info == NULL) {
		LOG(@"copyIdentifierAndEntitlements: args are NULL, returning");
		return;
	}

	LOG(@"bundle path = %@", path);
	NSBundle *bundle = [NSBundle bundleWithPath:path];

	NSString *bundleIdentifier = [bundle bundleIdentifier];
	if (bundleIdentifier != nil) {
		*identifier = [[NSString alloc] initWithString:bundleIdentifier];
		LOG(@"bundleID = %@", bundleIdentifier);
	}

	NSString *executablePath = [bundle executablePath];
	NSArray *paths = [executablePath pathComponents];
	if (paths.count > 0 && [paths.lastObject isEqualToString:@"Cydia"]) {
		NSMutableArray *newPaths = [NSMutableArray arrayWithArray:paths];
		newPaths[newPaths.count - 1] = @"MobileCydia";
		executablePath = [NSString pathWithComponents:newPaths];
	}
	LOG(@"bundle exec path = %@", executablePath);

	NSMutableData *data = [NSMutableData data];
	int ret = copyEntitlementDataFromFile(executablePath.UTF8String, (CFMutableDataRef) data);
	if (ret == kCopyEntSuccess) {
		NSError *error;
		NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:&error];
		NSMutableDictionary *mutableInfo = [[NSMutableDictionary alloc] initWithDictionary:plist];
		if ([mutableInfo objectForKey:@"application-identifier"] == nil) {
			if ([mutableInfo objectForKey:@"com.apple.developer.team-identifier"] != nil) {
				[mutableInfo setObject:[NSString stringWithFormat:@"%@.%@", [mutableInfo objectForKey:@"com.apple.developer.team-identifier"], bundleIdentifier] forKey:@"application-identifier"];
			} else {
				[mutableInfo setObject:bundleIdentifier forKey:@"application-identifier"];
			}
		}
		*info = [mutableInfo copy];
	} else {
		LOG(@"Failed to fetch entitlements: %@", (NSString *) entErrorString(ret));
	}
}

DECL_FUNC(SecCertificateCreateWithData, SecCertificateRef, CFAllocatorRef allocator, CFDataRef data) {
	SecCertificateRef result = original_SecCertificateCreateWithData(allocator, data);
	LOG(@"orig SecCertificateRef = %@", (NSData *)result);
	if (result == NULL) {
		// Returning kSecMagicBytes causes Security.framework to crash installd on iOS 10
		// When this occurs in uicache, the LaunchServices caches become corrupt and the user enters a respring/"boot" loop
		CFDataRef dataRef = CFDataCreate(NULL, kSecMagicBytes, kSecMagicBytesLength);
		LOG(@"ASU SecCertificateRef = %@", (NSData *)dataRef);
		// As a workaround, return the actual Apple intermediate certificate on iOS 10 only
		if (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_10_0 && data != NULL && CFEqual(dataRef, data)) {
			result = (SecCertificateRef) dataRef;
		} else {
			CFRelease(dataRef);
		}
	}
	return result;
}

DECL_FUNC(SecCertificateCopySubjectSummary, CFStringRef, SecCertificateRef certificate) {
	if (CFGetTypeID(certificate) == CFDataGetTypeID()) {
		return CFStringCreateWithCString(NULL, kSecSubjectCStr, kCFStringEncodingUTF8);
	}
	CFStringRef result = original_SecCertificateCopySubjectSummary(certificate);
	return result;
}

DECL_FUNC(MISValidateSignatureAndCopyInfo, uintptr_t, NSString *path, uintptr_t b, NSDictionary **info) {
	if (access(DPKG_PATH, F_OK) == -1) {
		NSLog(@"You seem to have installed AppSync Unified from an APT repository that is not diatr.us/nito (package ID us.diatr.appsyncunified).");
		NSLog(@"If someone other than Linus Yang (laokongzi), Karen (angelXwind), or Diatrus is taking credit for the development of this tool, they are likely lying.");
		NSLog(@"Please only download AppSync Unified from the official repository to ensure file integrity and reliability.");
	}
	original_MISValidateSignatureAndCopyInfo(path, b, info);
	if (info == NULL) {
		LOG(@"info is NULL :c");
	} else if (*info == nil) {
		LOG(@"info is nil, returning faked info");
		if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0) {
			static dispatch_once_t onceToken;
			dispatch_once(&onceToken, ^{
				MSImageRef imageSec;
				LOG(@"Loading and injecting into Security.framework");
				LOAD_IMAGE(imageSec, "/System/Library/Frameworks/Security.framework/Security");
				LOG(@"Hooking SecCertificateCreateWithData");
				HOOK_FUNC(SecCertificateCreateWithData, imageSec);
				LOG(@"Hooking SecCertificateCopySubjectSummary");
				HOOK_FUNC(SecCertificateCopySubjectSummary, imageSec);
			});

			NSMutableDictionary *fakeInfo = [[NSMutableDictionary alloc] init];
			NSDictionary *entitlements = nil;
			NSString *identifier = nil;
			copyIdentifierAndEntitlements(path, &identifier, &entitlements);
			if (entitlements != nil) {
				[fakeInfo setObject:entitlements forKey:@"Entitlements"];
				if ([[fakeInfo objectForKey:@"Entitlements"] objectForKey:@"com.apple.developer.team-identifier"] != nil) {
					[fakeInfo setObject:[[fakeInfo objectForKey:@"Entitlements"] objectForKey:@"com.apple.developer.team-identifier"] forKey:@"TeamID"];
				}
				[entitlements release];
			}
			if (identifier != nil) {
				[fakeInfo setObject:identifier forKey:@"SigningID"];
				[identifier release];
			}
			
			[fakeInfo setObject:(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_10_0) ? [NSData dataWithBytes:kSecMagicBytes length:kSecMagicBytesLength] : [NSData dataWithBytes:kSecAppleCertificate length:kSecAppleCertificateLength] forKey:@"SignerCertificate"];
			[fakeInfo setObject:[NSDate date] forKey:@"SigningTime"];
			[fakeInfo setObject:[NSNumber numberWithBool:NO] forKey:@"ValidatedByProfile"];
			[fakeInfo setObject:[NSNumber numberWithBool:NO] forKey:@"ValidatedByUniversalProfile"];
			[fakeInfo setObject:[NSNumber numberWithBool:NO] forKey:@"ValidatedByLocalProfile"];
			*info = fakeInfo;
			LOG(@"ASU faked info = %@", *info);
		}
	} else {
		LOG(@"orig info is okay, proceed");
		LOG(@"orig info = %@", *info);
	}
	return 0;
}

%ctor {
	@autoreleasepool {
		MSImageRef image;
		LOG(@"Loading and injecting into libmis.dylib");
		LOAD_IMAGE(image, "/usr/lib/libmis.dylib");
		LOG(@"Hooking MISValidateSignatureAndCopyInfo");
		HOOK_FUNC(MISValidateSignatureAndCopyInfo, image);
	}
}
