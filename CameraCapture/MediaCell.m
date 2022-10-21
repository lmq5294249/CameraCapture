//
//  MediaCell.m
//  CameraCapture
//
//  Created by 林漫钦 on 2022/9/26.
//

#import "MediaCell.h"


@implementation MediaCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        self.fileNameLabel = [[UILabel alloc] init];
        self.fileNameLabel.textColor = [UIColor whiteColor];
        self.fileNameLabel.font = [UIFont systemFontOfSize:16.0];
        self.fileNameLabel.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:self.fileNameLabel];
        
        self.loadBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.loadBtn setImage:[UIImage imageNamed:@"CameraCapture.download"] forState:UIControlStateNormal];
        self.loadBtn.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:self.loadBtn];
        [self.loadBtn addTarget:self action:@selector(didClickLoadBtn:) forControlEvents:UIControlEventTouchUpInside];
        
        self.deleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.deleteBtn setImage:[UIImage imageNamed:@"CameraCapture.delete"] forState:UIControlStateNormal];
        [self.contentView addSubview:self.deleteBtn];
        [self.deleteBtn addTarget:self action:@selector(didClickDeleteBtn:) forControlEvents:UIControlEventTouchUpInside];
        
        self.playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.playBtn setImage:[UIImage imageNamed:@"CameraCapture.playBtn"] forState:UIControlStateNormal];
        [self.contentView addSubview:self.playBtn];
        [self.playBtn addTarget:self action:@selector(didClickPlayBtn:) forControlEvents:UIControlEventTouchUpInside];
        
        self.line = [[UIView alloc] init];
        self.line.backgroundColor = [UIColor colorWithWhite:0.6 alpha:0.7];
        [self.contentView addSubview:self.line];
        
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.fileNameLabel.frame = CGRectMake(16, 0, CGRectGetWidth(self.frame) * 0.65, CGRectGetHeight(self.frame));
    
    self.playBtn.frame = CGRectMake(CGRectGetWidth(self.frame) - 44*3 - 16*3, (CGRectGetHeight(self.frame) - 44)/2, 44, 44);
    
    self.loadBtn.frame = CGRectMake(CGRectGetWidth(self.frame) - 44*2 - 16*2, (CGRectGetHeight(self.frame) - 44)/2, 44, 44);
    
    self.deleteBtn.frame = CGRectMake(CGRectGetWidth(self.frame) - 44 - 16, (CGRectGetHeight(self.frame) - 44)/2, 44, 44);
    
    self.line.frame = CGRectMake(0, CGRectGetHeight(self.frame), CGRectGetWidth(self.frame), 1);
}

- (void)setModel:(MediaModel *)model
{
    _model = model;
    if (_model) {
        self.fileNameLabel.text = model.fileName;
    }
    
    if (model.mediaType == MediaTypePhoto) {
        self.playBtn.hidden = YES;
    }
    else{
        self.playBtn.hidden = NO;
    }
}

- (void)didClickLoadBtn:(UIButton *)btn
{
    self.didButtonClickBlock(self.model, MediaButtonTypeLoad);
}

- (void)didClickDeleteBtn:(UIButton *)btn
{
    self.didButtonClickBlock(self.model, MediaButtonTypeDelete);
}

- (void)didClickPlayBtn:(UIButton *)btn
{
    self.didButtonClickBlock(self.model, MediaButtonTypePlay);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}
@end
