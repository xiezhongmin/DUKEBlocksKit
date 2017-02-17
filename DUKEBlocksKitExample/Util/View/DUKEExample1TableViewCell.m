//
//  DUKEExample1TableViewCell.m
//  DUKEBlocksKitExample
//
//  Copyright © 2016年 请叫我杜克. All rights reserved.
//

#import "DUKEExample1TableViewCell.h"
#import "DUKEExample1Model.h"

#define ImagePath(path,name) [NSString stringWithFormat:@"%@.bundle/%@", path, name]
@interface DUKEExample1TableViewCell ()
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *htmlLabel;
@end

@implementation DUKEExample1TableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)configureCellWithModel:(DUKEExample1Model *)model {
    self.iconImageView.image = [UIImage imageNamed:ImagePath(@"assets", model.icon)];
    
    self.nameLabel.text = model.name;
    
    self.htmlLabel.text = model.html;
}
@end
