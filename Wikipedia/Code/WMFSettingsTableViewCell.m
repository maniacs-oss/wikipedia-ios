#import "WMFSettingsTableViewCell.h"
#import "Wikipedia-Swift.h"

@interface WMFSettingsTableViewCell ()

@property (strong, nonatomic) IBOutlet UIImageView *titleIcon;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *disclosureLabel;
@property (strong, nonatomic) IBOutlet UIImageView *disclosureIcon;
@property (strong, nonatomic) IBOutlet UIButton *titleButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLabelLeadingWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleButtonLeadingWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageLeadingWidth;
@property (nonatomic) CGFloat titleLabelLeadingWidthForVisibleImage;
@property (nonatomic) NSInteger controlTag;
@property (nonatomic) BOOL isSwitchOn;
@property (nonatomic, strong) WMFTheme *theme;
@property (nonatomic, strong) UIColor *labelBackgroundColor;

@end

@implementation WMFSettingsTableViewCell

- (void)setTitle:(NSString *)title {
    _title = title;
    self.titleLabel.text = title;
}

- (void)setButtonTitle:(NSString *)buttonTitle {
    [self.titleButton setTitle:buttonTitle forState:UIControlStateNormal];
}

-(NSString *)buttonTitle {
    return self.titleButton.titleLabel.text;
}

- (void)setIconName:(NSString *)iconName {
    _iconName = iconName;
    self.titleIcon.image = [[UIImage imageNamed:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    if (_iconName) {
        self.titleIcon.hidden = NO;
        self.titleLabelLeadingWidth.constant = self.titleLabelLeadingWidthForVisibleImage;
    } else {
        self.titleIcon.hidden = YES;
        self.titleLabelLeadingWidth.constant = self.imageLeadingWidth.constant;
    }
    self.titleButtonLeadingWidth.constant = self.titleLabelLeadingWidth.constant;
}

- (void)setDisclosureText:(NSString *)disclosureText {
    _disclosureText = disclosureText;
    self.disclosureLabel.text = disclosureText;
}

- (UIImage *)backChevronImage {
    static dispatch_once_t once;
    static UIImage *image;
    dispatch_once(&once, ^{
        image = [[UIImage wmf_imageFlippedForRTLLayoutDirectionNamed:@"chevron-right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    });
    return image;
}

- (UIImage *)externalLinkImage {
    static dispatch_once_t once;
    static UIImage *image;
    dispatch_once(&once, ^{
        image = [[UIImage wmf_imageFlippedForRTLLayoutDirectionNamed:@"mini-external"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    });
    return image;
}

- (void)setControlTag:(NSInteger)controlTag {
    self.disclosureSwitch.tag = controlTag;
    self.titleButton.tag = controlTag;
}

- (void)setIsSwitchOn:(BOOL)isSwitchOn {
    _isSwitchOn = isSwitchOn;
    [self.disclosureSwitch setOn:isSwitchOn];
}

- (void)setDisclosureType:(WMFSettingsMenuItemDisclosureType)disclosureType {
    _disclosureType = disclosureType;
    switch (disclosureType) {
        case WMFSettingsMenuItemDisclosureType_None:
            self.disclosureIcon.hidden = YES;
            self.disclosureLabel.hidden = YES;
            self.disclosureIcon.image = nil;
            self.disclosureSwitch.hidden = YES;
            break;
        case WMFSettingsMenuItemDisclosureType_ExternalLink:
            self.disclosureIcon.hidden = NO;
            self.disclosureLabel.hidden = YES;
            self.disclosureIcon.image = [self externalLinkImage];
            self.disclosureSwitch.hidden = YES;
            break;
        case WMFSettingsMenuItemDisclosureType_Switch:
            self.disclosureIcon.hidden = YES;
            self.disclosureLabel.hidden = YES;
            self.disclosureIcon.image = nil;
            self.disclosureSwitch.hidden = NO;
            [self.disclosureSwitch addTarget:self action:@selector(didToggleDisclosureSwitch:) forControlEvents:UIControlEventValueChanged];
            self.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        case WMFSettingsMenuItemDisclosureType_ViewController:
            self.disclosureIcon.hidden = NO;
            self.disclosureLabel.hidden = YES;
            self.disclosureIcon.image = [self backChevronImage];
            self.disclosureSwitch.hidden = YES;
            break;
        case WMFSettingsMenuItemDisclosureType_ViewControllerWithDisclosureText:
            self.disclosureIcon.hidden = NO;
            self.disclosureLabel.hidden = NO;
            self.disclosureIcon.image = [self backChevronImage];
            self.disclosureSwitch.hidden = YES;
            break;
        case WMFSettingsMenuItemDisclosureType_TitleButton:
            self.disclosureIcon.hidden = YES;
            self.disclosureLabel.hidden = YES;
            self.disclosureIcon.image = nil;
            self.disclosureSwitch.hidden = YES;
            self.titleButton.hidden = NO;
            [self.titleButton addTarget:self action:@selector(didPressButton:) forControlEvents:UIControlEventTouchUpInside];
            break;
        default:
            break;
    }
}

- (void)didToggleDisclosureSwitch:(UISwitch *)sender {
    [self.delegate settingsTableViewCell:self didToggleDisclosureSwitch:sender];
}

- (void)didPressButton:(UIButton *)sender {
    [self.delegate settingsTableViewCell:self didPressButton:sender];
}

- (void)setIconColor:(UIColor *)iconColor {
    _iconColor = iconColor;
    self.titleIcon.tintColor = iconColor;
}

- (void)setIconBackgroundColor:(UIColor *)iconBackgroundColor {
    _iconBackgroundColor = iconBackgroundColor;
    self.titleIcon.backgroundColor = iconBackgroundColor;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    //HAX: reset the titleIcon's background color so it remains during the selection cell selection animation.
    self.iconColor = self.iconColor;
    self.iconBackgroundColor = self.iconBackgroundColor;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    //HAX: reset the titleIcon's background color so there's not a tiny flicker at the beginning of the selection cell selection animation.
    self.iconColor = self.iconColor;
    self.iconBackgroundColor = self.iconBackgroundColor;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundView = [UIView new];
    self.selectedBackgroundView = [UIView new];
    self.titleLabelLeadingWidthForVisibleImage = self.titleLabelLeadingWidth.constant;
    [self wmf_configureSubviewsForDynamicType];
}

- (void)configure:(WMFSettingsMenuItemDisclosureType)disclosureType title:(NSString *)title iconName:(NSString *)iconName isSwitchOn:(BOOL)isSwitchOn iconColor:(UIColor *)iconColor iconBackgroundColor:(UIColor *)iconBackgroundColor buttonTitle:(NSString *)buttonTitle controlTag:(NSInteger)controlTag theme:(WMFTheme *)theme {
    self.isSwitchOn = isSwitchOn;
    self.disclosureType = disclosureType;
    self.title = title;
    self.iconName = iconName;
    self.iconColor = iconColor;
    self.iconBackgroundColor = iconBackgroundColor;
    self.buttonTitle = buttonTitle;
    self.controlTag = controlTag;

    [self applyTheme:theme];
}

- (void)setLabelBackgroundColor:(UIColor *)labelBackgroundColor {
    self.titleLabel.backgroundColor = labelBackgroundColor;
    self.disclosureLabel.backgroundColor = labelBackgroundColor;
    self.titleButton.titleLabel.backgroundColor = labelBackgroundColor;
}

- (void)applyTheme:(WMFTheme *)theme {
    self.theme = theme;
    self.selectedBackgroundView.backgroundColor = theme.colors.midBackground;
    self.backgroundView.backgroundColor = theme.colors.paperBackground;
    self.titleLabel.textColor = theme.colors.primaryText;
    self.disclosureLabel.textColor = theme.colors.secondaryText;
    self.iconBackgroundColor = theme.colors.iconBackground == NULL ? self.iconBackgroundColor : theme.colors.iconBackground;
    self.iconColor = theme.colors.icon == NULL ? self.iconColor : theme.colors.icon;
    self.disclosureIcon.tintColor = theme.colors.secondaryText;
    self.disclosureSwitch.backgroundColor = theme.colors.paperBackground;
    self.labelBackgroundColor = theme.colors.paperBackground;
}

@end
