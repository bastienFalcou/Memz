//
//  MZWordDescriptionHeaderView.m
//  Memz
//
//  Created by Bastien Falcou on 12/26/15.
//  Copyright © 2015 Falcou. All rights reserved.
//

#import "MZWordDescriptionHeaderView.h"
#import "UIVIew+MemzAdditions.h"
#import "UIImage+MemzAdditions.h"

@interface MZWordDescriptionHeaderView ()

@property (weak, nonatomic) IBOutlet UILabel *wordLabel;
@property (weak, nonatomic) IBOutlet UIImageView *flagImageView;
@property (weak, nonatomic) IBOutlet UILabel *learnedStatusLabel;
@property (weak, nonatomic) IBOutlet UIView *learnedStatusView;
@property (weak, nonatomic) IBOutlet UILabel *numberOfTranslationsLabel;
@property (weak, nonatomic) IBOutlet UILabel *percentageSuccessLabel;
@property (weak, nonatomic) IBOutlet UIButton *editButton;

@property (assign, nonatomic) BOOL isEditing;

@end

@implementation MZWordDescriptionHeaderView

- (void)awakeFromNib {
	[super awakeFromNib];

	[self.learnedStatusView makeCircular];
}

- (void)setWord:(MZWord *)word {
	_word = word;

	self.wordLabel.text = word.word;
	self.flagImageView.image = [UIImage flagImageForLanguage:self.word.language.integerValue];
}

#pragma mark - Edition 

- (void)setIsEditing:(BOOL)isEditing {
	_isEditing = isEditing;

	if (!isEditing) {
		[self.editButton setTitle:NSLocalizedString(@"CommonDone", nil) forState:UIControlStateNormal];
		if ([self.delegate respondsToSelector:@selector(wordDescriptionHeaderViewDidStartEditing:)]) {
			[self.delegate wordDescriptionHeaderViewDidStartEditing:self];
		}
	} else {
		[self.editButton setTitle:NSLocalizedString(@"CommonEdit", nil) forState:UIControlStateNormal];
		if ([self.delegate respondsToSelector:@selector(wordDescriptionHeaderViewDidStopEditing:)]) {
			[self.delegate wordDescriptionHeaderViewDidStopEditing:self];
		}
	}
}

#pragma mark - Actions

- (IBAction)editButtonTapped:(id)sender {
	self.isEditing = !self.isEditing;
}

@end
