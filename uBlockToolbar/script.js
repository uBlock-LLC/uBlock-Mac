var reOS = /(CrOS\ \w+|Windows\ NT|Mac\ OS\ X|Linux)\ ([\d\._]+)?/;

var matches = reOS.exec(navigator.userAgent);

var operatingSystem = (matches || [])[1] || "Unknown";

var operatingSystemVersion = (matches || [])[2] || "Unknown";

var reBW = /(MSIE|Trident|(?!Gecko.+)Firefox|(?!AppleWebKit.+Chrome.+)Safari(?!.+Edge)|(?!AppleWebKit.+)Chrome(?!.+Edge)|(?!AppleWebKit.+Chrome.+Safari.+)Edge|AppleWebKit(?!.+Chrome|.+Safari)|Gecko(?!.+Firefox))(?: |\/)([\d\.apre]+)/;

matches = reBW.exec(navigator.userAgent);

var browserVersion = (matches || [])[2] || "Unknown";

var browserLanguage = navigator.language.match(/^[a-z]+/i)[0];

function dispatchPingDataInfo() {
    safari.extension.dispatchMessage("PING_DATA_INFO", {
                                     "version": browserVersion,
                                     "lang": browserLanguage,
                                     "os": operatingSystem,
                                     "os_version": operatingSystemVersion
                                     });
}

dispatchPingDataInfo()
