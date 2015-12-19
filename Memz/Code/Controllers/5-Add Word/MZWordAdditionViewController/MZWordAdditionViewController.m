//
//  MZWordAdditionViewController.m
//  Memz
//
//  Created by Bastien Falcou on 12/16/15.
//  Copyright © 2015 Falcou. All rights reserved.
//

#import "MZWordAdditionViewController.h"
#import "MZWordAdditionTableViewHeader.h"
#import "MZTextFieldTableViewCell.h"
#import "MZTranslatedWordTableViewCell.h"
#import "NSManagedObject+MemzCoreData.h"
#import "MZWord+CoreDataProperties.h"
#import "MZDataManager.h"

typedef NS_ENUM(NSInteger, MZWordAdditionSectionType) {
	MZWordAdditionSectionTypeWord,
	MZWordAdditionSectionTypeTranslations,
	MZWordAdditionSectionTypeSuggestions
};

typedef NS_ENUM(NSInteger, MZWordAdditionWordRowType) {
	MZWordAdditionWordRowTypeNewWord,
	MZWordAdditionWordRowTypeTranslation
};

NSString * const kWordAdditionTableViewHeaderIdentifier = @"MZWordAdditionTableViewHeaderIdentifier";
NSString * const kTextFieldTableViewCellIdentifier = @"MZTextFieldTableViewCellIdentifier";
NSString * const kTranslatedWordTableViewCellIdentifier = @"MZTranslatedWordTableViewCellIdentifier";

NSString * const kSectionTypeKey = @"SectionTypeKey";
NSString * const kSectionTitleKey = @"SectionTitleKey";
NSString * const kWordRowTypeKey = @"WordRowTypeKey";
NSString * const kContentTypeKey = @"ContentTypeKey";

const CGFloat kTableViewSectionHeaderHeight = 40.0f;
const CGFloat kWordAdditionTypeWordCellHeight = 50.0f;

@interface MZWordAdditionViewController () <UITableViewDataSource,
UITableViewDelegate,
MZTextFieldTableViewCellDelegate,
MZTranslatedWordTableViewCellDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewTopConstraint;

@property (weak, nonatomic, readonly) NSArray<NSDictionary *> *tableViewData;

@property (strong, nonatomic) NSString *wordToTranslate;
@property (strong, nonatomic) NSMutableArray<NSString *> *wordTranslations;
@property (strong, nonatomic) NSArray<NSString *> *wordSuggestions;

@end

@implementation MZWordAdditionViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	self.title = @"Add New Word";  // TODO: Localize and designs

	UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Navigation-Cancel"]
																																	style:UIBarButtonItemStylePlain
																																target:self
																																action:@selector(didTapCloseButton:)];
	[self.navigationItem setLeftBarButtonItem:leftButton];
	self.wordTranslations = [[NSMutableArray alloc] init];

	[self setupTableView];
	[self.tableView reloadData];
}

#pragma mark - Setups

- (void)setupTableView {
	[self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([MZWordAdditionTableViewHeader class]) bundle:nil] forHeaderFooterViewReuseIdentifier:kWordAdditionTableViewHeaderIdentifier];
}

#pragma mark - Data Management

- (NSArray *)tableViewData {
	NSMutableArray *mutableArray = [[NSMutableArray alloc] init];

	[mutableArray addObject:@{kSectionTypeKey: @(MZWordAdditionSectionTypeWord),
														kSectionTitleKey: @"Your word",
														kContentTypeKey: @[@{kWordRowTypeKey: @(MZWordAdditionWordRowTypeNewWord),
																								 kContentTypeKey: self.wordToTranslate ?: @""},
																							 @{kWordRowTypeKey: @(MZWordAdditionWordRowTypeTranslation),
																								 kContentTypeKey: @""}]}];

	if (self.wordTranslations.count) {
		[mutableArray addObject:@{kSectionTypeKey: @(MZWordAdditionSectionTypeTranslations),
															kSectionTitleKey: @"Your translations",
															kContentTypeKey: self.wordTranslations}];
	}

	if (self.wordSuggestions.count) {
		[mutableArray addObject:@{kSectionTypeKey: @(MZWordAdditionSectionTypeSuggestions),
															kSectionTitleKey: @"Suggested translations",
															kContentTypeKey: self.wordSuggestions}];
	}

	return mutableArray;
}

#pragma mark - Table View Data Source & Delegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return kTableViewSectionHeaderHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.tableViewData.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  MZWordAdditionTableViewHeader *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kWordAdditionTableViewHeaderIdentifier];
	headerView.headerTitle.text = [self.tableViewData[section][kSectionTitleKey] safeCastToClass:[NSString class]];
	headerView.backgroundColor = [UIColor mainBackgroundColor];
	headerView.bottomSeparatorView.backgroundColor = [UIColor secondaryBackgroundColor];
	return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch ([self.tableViewData[indexPath.section][kSectionTypeKey] integerValue]) {
		case MZWordAdditionSectionTypeWord:
			return kWordAdditionTypeWordCellHeight;
		default:
			return UITableViewAutomaticDimension;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.tableViewData[section][kContentTypeKey] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch ([self.tableViewData[indexPath.section][kSectionTypeKey] integerValue]) {
		case MZWordAdditionSectionTypeWord: {
			MZTextFieldTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTextFieldTableViewCellIdentifier
																																			 forIndexPath:indexPath];
			cell.bottomSeparator.backgroundColor = [UIColor secondaryBackgroundColor];
			cell.delegate = self;

			if ([self.tableViewData[indexPath.section][kContentTypeKey][indexPath.row][kWordRowTypeKey] integerValue] == MZWordAdditionWordRowTypeNewWord) {
				cell.cellType = MZTextFieldTableViewCellTypeRegular;
			} else {
				cell.cellType = MZTextFieldTableViewCellTypeAddition;
			}
			return cell;
		}

		case MZWordAdditionSectionTypeTranslations: {
			MZTranslatedWordTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTranslatedWordTableViewCellIdentifier
																																						forIndexPath:indexPath];
			cell.translatedWordLabel.text = self.wordTranslations[indexPath.row];
			cell.bottomSeparator.backgroundColor = [UIColor secondaryBackgroundColor];
			cell.delegate = self;
			return cell;
		}

		default:
			return nil;
		}
}

#pragma mark - Text Field Cells Delegate Methods

- (void)textFieldTableViewCellDidTapAddButton:(MZTextFieldTableViewCell *)cell {
	// TODO: Check if valid

	if ([self.wordTranslations containsObject:cell.textField.text]) {
		// TODO: Show error
		return;
	}

	[self.wordTranslations addObject:cell.textField.text];

	if (self.wordTranslations.count == 1) {
		[self.tableView insertSections:[NSIndexSet indexSetWithIndex:MZWordAdditionSectionTypeTranslations]
									withRowAnimation:UITableViewRowAnimationFade];
	} else {
		[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.wordTranslations.count - 1
																																inSection:MZWordAdditionSectionTypeTranslations]]
													withRowAnimation:UITableViewRowAnimationFade];
	}

	cell.textField.text = @"";
	[self.view endEditing:YES];
}

- (void)textFieldTableViewCell:(MZTextFieldTableViewCell *)cell textDidChange:(NSString *)text {
	NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
	if (indexPath.section == MZWordAdditionSectionTypeWord && indexPath.row == MZWordAdditionWordRowTypeNewWord) {
		self.wordToTranslate = text;

		// TODO: Update if needed looking for strings that start with same letters
	}
}

#pragma mark - Translated Word Cells Delegate Methods

- (void)translatedWordTableViewCellDidTapRemoveButton:(MZTranslatedWordTableViewCell *)cell {
	NSUInteger wordTranslationIndex = [self.wordTranslations indexOfObject:cell.translatedWordLabel.text];
	[self.wordTranslations removeObjectAtIndex:wordTranslationIndex];

	if (self.wordTranslations.count == 0) {
		[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:MZWordAdditionSectionTypeTranslations]
									withRowAnimation:UITableViewRowAnimationFade];
	} else {
		[self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:wordTranslationIndex
																																inSection:MZWordAdditionSectionTypeTranslations]]
													withRowAnimation:UITableViewRowAnimationFade];
	}
}

#pragma mark - Actions

- (void)didTapCloseButton:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didTapAddWordButton:(id)sender {
	// TODO: Test texts not empty, etc.

	[MZWord addWord:self.wordToTranslate
		 fromLanguage:[MZLanguageManager sharedManager].fromLanguage
		 translations:self.wordTranslations
			 toLanguage:[MZLanguageManager sharedManager].toLanguage];

	[[MZDataManager sharedDataManager] saveChangesWithCompletionHandler:^{
		[self dismissViewControllerAnimated:YES completion:nil];
	}];
}

@end
