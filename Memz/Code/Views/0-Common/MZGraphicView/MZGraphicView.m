//
//  MZGraphicView.m
//  Memz
//
//  Created by Bastien Falcou on 2/6/16.
//  Copyright © 2016 Falcou. All rights reserved.
//

#import "MZGraphicView.h"
#import "UIColor+MemzAdditions.h"
#import "NSDate+MemzAdditions.h"

#define DEFAULT_GRADIENT_START_COLOR [UIColor graphGradientDefaultStartColor]
#define DEFAULT_GRADIENT_END_COLOR [UIColor graphGradientDefaultEndColor]
#define DEFAULT_GRADIENT_UNDER_GRAPH_START_COLOR [UIColor graphGradientDefaultUnderGraphStartColor]

const CGFloat kHorizontalInsets = 20.0f;

const CGFloat kLeftPointAdditionalInset = 10.0f;
const CGFloat kRightPointAdditionalInset = 40.0f;

const CGFloat kPointRadius = 4.0f;
const CGFloat kInnerPointRadius = 2.0f;

const CGFloat kTopSeparatorLineAdditionInset = 9.0f;
const CGFloat kTopBoundaryLabelInset = 5.0f;

const CGFloat kTintColorMakeBrighterPercentage = 0.2f;
const CGFloat kTextAlphaPercentage = 0.7f;
const CGFloat kPercentageShouldDisplayOriginZero = 0.3f;

@interface MZGraphicView ()

@property (nonatomic, strong) IBOutlet UIView *titleContainerView;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *averageLabel;
@property (nonatomic, strong) IBOutlet UILabel *totalValuesLabel;
@property (nonatomic, strong) IBOutlet UILabel *timeStampLabel;

@property (nonatomic, strong) IBOutlet UIView *metricsContainerView;

@property (nonatomic, strong) NSMutableArray<UIView *> *metricsViews;

@end

@implementation MZGraphicView
@synthesize textColor = _textColor;
@synthesize textFont = _textFont;

#pragma mark - Initialization

- (instancetype)init {
	if (self = [super init]) {
		[self commonInit];
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		[self commonInit];
	}
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		[self commonInit];
	}
	return self;
}

- (void)commonInit {
	self.gradientStartColor = DEFAULT_GRADIENT_START_COLOR;
	self.gradientEndColor = DEFAULT_GRADIENT_END_COLOR;
	self.gradientUnderGraphStartColor = DEFAULT_GRADIENT_UNDER_GRAPH_START_COLOR;

	self.showAverageLine = YES;
	self.textColor = [UIColor whiteColor];

	self.title = NSLocalizedString(@"StatisticsGraphDefaultTitle", nil);
	self.metricText = NSLocalizedString(@"StatisticsGraphDefaultMetricText", nil);

	self.metricsViews = [[NSMutableArray alloc] init];
}

#pragma mark - Public Methods

- (void)transitionToValues:(NSArray<NSNumber *> *)values withMetrics:(NSArray<NSString *> *)metrics animated:(BOOL)animated {
	_values = values;
	_metrics = metrics;

	// (1) Draw background gradient
	[self drawBackgroundGradient];

	// (2) Draw under graph gradient
	[self drawUnderGraphGradient];

	// (3) Draw graph line
	[self drawLine];

	// (4) Draw points
	[self drawPoints];

	// (5) Draw average dashed line
	if (self.showAverageLine) {
		[self drawDashedLine];
	}

	// (6) Draw top and bottom separation lines
	[self drawTopSeparationLine];
	[self drawBottomSeparatorLine];

	// (7) Draw bottom metrics
	[self drawBottomMetricsViews];

	// (8) Draw right minimum and maximum values
	[self drawTopBoundaryValue];
	[self drawBottomBoundaryValue];

	// (9) Update labels
	[self updateLabelsText];
}

#pragma mark - Custom Setters

- (void)setTextFont:(UIFont *)textFont {
	_textFont = textFont;

	[self updateLabelsStyle];
}

- (UIFont *)textFont {
	return _textFont ?: self.titleLabel.font;
}

- (void)setTextColor:(UIColor *)textColor {
	_textColor = textColor;

	[self updateLabelsStyle];
}

- (UIColor *)textColor {
	return _textColor ?: self.titleLabel.textColor;
}

- (void)setTitle:(NSString *)title {
	_title = title;

	self.titleLabel.text = title;
}

- (void)setMetricText:(NSString *)metricText {
	_metricText = metricText;

	self.totalValuesLabel.attributedText = [self totalValuesAttributedString];
}

- (void)setYOriginType:(MZGraphYOriginType)yOriginType {
	_yOriginType = yOriginType;

	[self transitionToValues:self.values withMetrics:self.metrics animated:NO];
}

#pragma mark - Global Overridden Methods

- (void)awakeFromNib {
	[super awakeFromNib];

	[self updateLabelsStyle];
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];

	// (1) Add rounded corners
	UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect
																						 byRoundingCorners:UIRectCornerAllCorners
																									 cornerRadii:CGSizeMake(8.0f, 8.0f)];
	[path addClip];

	// (2) Update Graph
	[self transitionToValues:self.values withMetrics:self.metrics animated:NO];
}

#pragma mark - Points Calculations

- (CGFloat)xPointForColumn:(NSInteger)column {
	CGFloat spacer = (self.bounds.size.width - kHorizontalInsets * 2 - kLeftPointAdditionalInset - kRightPointAdditionalInset) / (self.values.count - 1);
	return column * spacer + kHorizontalInsets + kLeftPointAdditionalInset;
}

- (CGFloat)yPointForValue:(NSNumber *)value {
	CGFloat graphHeight = self.frame.size.height - self.titleContainerView.frame.size.height - self.metricsContainerView.frame.size.height;

	CGFloat (^ graphYOriginZero)() = ^() {
		CGFloat percentageHeight = value.floatValue / [self maximumValue].floatValue;
		CGFloat yPoint = percentageHeight * graphHeight;
		return self.titleContainerView.frame.size.height + graphHeight - yPoint;
	};

	CGFloat (^ graphYOriginMinimumValue)() = ^() {
		CGFloat percentageHeight = (value.floatValue - [self minimumValue].floatValue) / ([self maximumValue].floatValue
        - [self minimumValue].floatValue);
		CGFloat yPoint = percentageHeight * graphHeight;
		return self.titleContainerView.frame.size.height + graphHeight - yPoint;
	};

	switch (self.yOriginType) {
		case MZGraphYOriginTypeAutomatic: {
			return [self shouldDisplayOriginZero] ? graphYOriginZero() : graphYOriginMinimumValue();
		}
		case MZGraphYOriginTypeZero: {
			return graphYOriginZero();
		}
		case MZGraphYOriginTypeMinimumValue: {
			return graphYOriginMinimumValue();
		}
	}
}

- (CGFloat)yPointForColumn:(NSInteger)column {
	return [self yPointForValue:self.values[column]];
}

#pragma mark - Gradient Background

- (CGGradientRef)generateBackgroundGradient {
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

	CFMutableArrayRef colorArray = CFArrayCreateMutable(NULL, 2, &kCFTypeArrayCallBacks);
	CFArrayAppendValue(colorArray, self.gradientStartColor.CGColor);
	CFArrayAppendValue(colorArray, self.gradientEndColor.CGColor);

	CGFloat colorLocations[2] = {0.0f, 1.0f};

	return CGGradientCreateWithColors(colorSpace, colorArray, colorLocations);
}

- (void)drawBackgroundGradient {
	CGPoint startPoint = CGPointZero;
	CGPoint endPoint = CGPointMake(0.0f, self.bounds.size.height);
	CGContextDrawLinearGradient(UIGraphicsGetCurrentContext(),
															[self generateBackgroundGradient],
															startPoint,
															endPoint,
															kCGGradientDrawsBeforeStartLocation);
}

#pragma mark - Under Graph Gradient

- (CGGradientRef)generateUnderGraphGradient {
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

	CFMutableArrayRef colorArray = CFArrayCreateMutable(NULL, 2, &kCFTypeArrayCallBacks);
	CFArrayAppendValue(colorArray, self.gradientUnderGraphStartColor.CGColor);
	CFArrayAppendValue(colorArray, self.gradientEndColor.CGColor);

	CGFloat colorLocations[2] = {0.0f, 1.0f};

	return CGGradientCreateWithColors(colorSpace, colorArray, colorLocations);
}

- (void)drawUnderGraphGradient {
	CGContextSaveGState(UIGraphicsGetCurrentContext());

	UIBezierPath *graphPath = [self generateGraphLine];

	[graphPath addLineToPoint:CGPointMake([self xPointForColumn:self.values.count - 1], self.frame.size.height)];
	[graphPath addLineToPoint:CGPointMake([self xPointForColumn:0], self.frame.size.height)];
	[graphPath closePath];

	[graphPath addClip];

	[[UIColor greenColor] setFill];
	UIBezierPath *rectPath = [UIBezierPath bezierPathWithRect:self.bounds];
	[rectPath fill];

	NSUInteger indexMaxValue = [self.values indexOfObject:[self maximumValue]];
	CGFloat highestPoint = [self yPointForColumn:indexMaxValue];

	CGPoint startPoint = CGPointMake(kHorizontalInsets, highestPoint);
	CGPoint endPoint = CGPointMake(kHorizontalInsets, self.bounds.size.height);

	CGContextDrawLinearGradient(UIGraphicsGetCurrentContext(),
															[self generateUnderGraphGradient],
															startPoint,
															endPoint,
															kCGGradientDrawsBeforeStartLocation);

	CGContextRestoreGState(UIGraphicsGetCurrentContext());
}

#pragma mark - Graph Line

- (UIBezierPath *)generateGraphLine {
	if (self.values.count == 0) {
		return nil;
	}

	[[UIColor whiteColor] setFill];
	[[UIColor whiteColor] setStroke];

	UIBezierPath *graphPath = [[UIBezierPath alloc] init];
	[graphPath moveToPoint:CGPointMake([self xPointForColumn:0], [self yPointForColumn:0])];

	for (NSUInteger i = 1; i < self.values.count; i++) {
		CGPoint nextPoint = CGPointMake([self xPointForColumn:i], [self yPointForColumn:i]);
		[graphPath addLineToPoint:nextPoint];
	}
	return graphPath;
}

- (void)drawLine {
	UIBezierPath *graphLine = [self generateGraphLine];
	graphLine.lineWidth = 1.0f;
	[graphLine stroke];
}

#pragma mark - Points

- (void)drawPoints {
	for (NSUInteger i = 0; i < self.values.count; i++) {
		CGPoint point = CGPointMake([self xPointForColumn:i], [self yPointForColumn:i]);
		point.x -= kPointRadius / 2.0f;
		point.y -= kPointRadius / 2.0f;

		UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(point.x,
																																						 point.y,
																																						 kPointRadius,
																																						 kPointRadius)];
		[[UIColor whiteColor] setFill];
		[circle fill];

		UIBezierPath *innerCircle = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(point.x + (kPointRadius - kInnerPointRadius) / 2.0f,
																																									point.y + (kPointRadius - kInnerPointRadius) / 2.0f,
																																									kInnerPointRadius,
																																									kInnerPointRadius)];

		[[UIColor averageColorBetweenColor:DEFAULT_GRADIENT_START_COLOR andColor:DEFAULT_GRADIENT_END_COLOR] setFill];
		[innerCircle fill];
	}
}

#pragma mark - Horizontal Average Dashed Line

- (void)drawDashedLine {
	UIBezierPath *linePath = [[UIBezierPath alloc] init];

	CGFloat dashArray[2] = {2.0f, 2.0f};
	[linePath setLineDash:dashArray count:2 phase:0];

	NSNumber *average = [self averageValue];

	[linePath moveToPoint:CGPointMake(kHorizontalInsets, [self yPointForValue:average])];
	[linePath addLineToPoint:CGPointMake(self.frame.size.width - kHorizontalInsets, [self yPointForValue:average])];

	[[[UIColor whiteColor] colorWithAlphaComponent:0.5f] setStroke];
	linePath.lineWidth = 1.0f;
	[linePath stroke];
}

#pragma mark - Horizontal Separator Lines

- (CGFloat)yTitleViewContainerBottomBaseline {
	CGPoint relativeTitleViewContainerBottomBaseline = CGPointMake(self.averageLabel.frame.origin.x,
																																 self.averageLabel.frame.origin.x + self.averageLabel.frame.size.height);
	CGPoint absolutetitleViewContainerBottomBaseline = [self.titleContainerView convertPoint:relativeTitleViewContainerBottomBaseline
																																										toView:self];
	return absolutetitleViewContainerBottomBaseline.y + kTopSeparatorLineAdditionInset;
}

- (void)drawTopSeparationLine {
	UIBezierPath *linePath = [[UIBezierPath alloc] init];

	[linePath moveToPoint:CGPointMake(kHorizontalInsets, [self yTitleViewContainerBottomBaseline])];
	[linePath addLineToPoint:CGPointMake(self.frame.size.width - kHorizontalInsets, [self yTitleViewContainerBottomBaseline])];

	[[self.tintColor colorWithAlphaComponent:0.8f] setStroke];
	linePath.lineWidth = 0.5f;
	[linePath stroke];
}

- (void)drawBottomSeparatorLine {
	UIBezierPath *linePath = [[UIBezierPath alloc] init];

	[linePath moveToPoint:CGPointMake(kHorizontalInsets,
																		self.metricsContainerView.frame.origin.y)];
	[linePath addLineToPoint:CGPointMake(self.frame.size.width - kHorizontalInsets,
																			 self.metricsContainerView.frame.origin.y)];

	[[[UIColor whiteColor] colorWithAlphaComponent:0.5f] setStroke];
	linePath.lineWidth = 0.5f;
	[linePath stroke];
}

#pragma mark - Draw Bottom Metrics

- (void)drawBottomMetricsViews {
	for (UIView *view in self.metricsViews) {
		[view removeFromSuperview];
	}
	[self.metricsViews removeAllObjects];

	for (NSUInteger i = 0; i < self.metrics.count; i++) {
		UILabel *metricView = [[UILabel alloc] init];
		metricView.text = self.metrics[i];
		metricView.font = [self.textFont fontWithSize:10.0f];
		metricView.textColor = [self.textColor colorWithAlphaComponent:i == self.metrics.count - 1 ? 1.0f : kTextAlphaPercentage];
		[metricView sizeToFit];

		CGFloat centerX = kHorizontalInsets + kLeftPointAdditionalInset + ((self.metricsContainerView.frame.size.width - 2
				* kHorizontalInsets - kLeftPointAdditionalInset - kRightPointAdditionalInset) / (self.metrics.count - 1)) * i;
		CGFloat centerY = self.metricsContainerView.frame.size.height / 2.0f;

		CGPoint centerPoint = CGPointMake(centerX, centerY);
		metricView.center = centerPoint;

		[self.metricsContainerView addSubview:metricView];
		[self.metricsViews addObject:metricView];
	}
}

#pragma mark - Draw Right Minimum & Maximum Values

- (void)drawTopBoundaryValue {
	NSString *yTopString = [NSString stringWithFormat:@"%.2f", [self maximumValue].floatValue];

	UILabel *topBoundaryLabel = [[UILabel alloc] init];
	topBoundaryLabel.text = yTopString;
	topBoundaryLabel.font = [self.textFont fontWithSize:10.0f];
	topBoundaryLabel.textColor = [self.tintColor makeBrighterWithCount:2];
	[topBoundaryLabel sizeToFit];

	CGFloat x = self.frame.size.width - kHorizontalInsets - topBoundaryLabel.frame.size.width / 2.0f;
	CGFloat y = [self yTitleViewContainerBottomBaseline] + topBoundaryLabel.frame.size.height / 2.0f + kTopBoundaryLabelInset;
	topBoundaryLabel.center = CGPointMake(x, y);

	[self addSubview:topBoundaryLabel];	// TODO: Store it in variable
}

- (void)drawBottomBoundaryValue {
	NSString *yOriginString = [NSString stringWithFormat:@"%.2f", [self bottomBoundaryNumber].floatValue];

	UILabel *bottomBoundaryLabel = [[UILabel alloc] init];
	bottomBoundaryLabel.text = yOriginString;
	bottomBoundaryLabel.font = [self.textFont fontWithSize:10.0f];
	bottomBoundaryLabel.textColor = [self.textColor colorWithAlphaComponent:kTextAlphaPercentage];
	[bottomBoundaryLabel sizeToFit];

	CGFloat x = self.frame.size.width - kHorizontalInsets - bottomBoundaryLabel.frame.size.width / 2.0f;
	CGFloat y = self.metricsContainerView.frame.origin.y - bottomBoundaryLabel.frame.size.width / 2.0f + kTopBoundaryLabelInset;
	bottomBoundaryLabel.center = CGPointMake(x, y);

	[self addSubview:bottomBoundaryLabel];	// TODO: Store it in variable
}

#pragma mark - Update Labels UI & Text

- (void)updateLabelsStyle {
	self.titleLabel.textColor = self.textColor;
	self.totalValuesLabel.textColor = self.textColor;
	self.averageLabel.textColor = [self.tintColor makeBrighterWithCount:2];
	self.timeStampLabel.textColor = [self.tintColor makeBrighterWithCount:2];

	self.titleLabel.font = [self.textFont fontWithSize:self.titleLabel.font.pointSize];
	self.averageLabel.font = [self.textFont fontWithSize:self.averageLabel.font.pointSize];
	self.timeStampLabel.font = [self.textFont fontWithSize:self.timeStampLabel.font.pointSize];

	self.totalValuesLabel.attributedText = [self totalValuesAttributedString];
}

- (void)updateLabelsText {
	self.titleLabel.text = self.title;
	self.averageLabel.text = [NSString stringWithFormat:NSLocalizedString(@"StatisticsGraphAverageTitle", nil), [self averageValue].floatValue];
	self.totalValuesLabel.attributedText = [self totalValuesAttributedString];
	self.timeStampLabel.text = [[NSDate date] humanReadableDateString];
}

#pragma mark - Helpers

- (NSNumber *)maximumValue {
	return [self.values valueForKeyPath:@"@max.self"];
}

- (NSNumber *)minimumValue {
	return [self.values valueForKeyPath:@"@min.self"];
}

- (NSNumber *)averageValue {
	return [self.values valueForKeyPath:@"@avg.self"];
}

- (NSNumber *)sumValue {
	return [self.values valueForKeyPath:@"@sum.self"];
}

- (BOOL)shouldDisplayOriginZero {
	if (self.yOriginType == MZGraphYOriginTypeZero || self.yOriginType == MZGraphYOriginTypeMinimumValue) {
		return self.yOriginType == MZGraphYOriginTypeZero;
	}
	return [self minimumValue].floatValue < [self maximumValue].floatValue * kPercentageShouldDisplayOriginZero;
}

- (NSNumber *)bottomBoundaryNumber {
	return [self shouldDisplayOriginZero] ? @0.0f : [self minimumValue];
}

- (NSAttributedString *)totalValuesAttributedString {
	if (!self.textFont || !self.textColor) {
		return nil;
	}

	NSString *sumValuesString = [NSString stringWithFormat:@"%.2f", self.values.lastObject.floatValue ?: 0.0f];
	NSString *totalValuesString = [NSString stringWithFormat:@"%@ %@", sumValuesString, self.metricText];

	NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:totalValuesString];

	[string addAttribute:NSForegroundColorAttributeName
								 value:self.textColor
								 range:NSMakeRange(0, totalValuesString.length)];

	[string addAttribute:NSFontAttributeName
								 value:[self.textFont fontWithSize:self.titleLabel.font.pointSize]
								 range:NSMakeRange(0, sumValuesString.length)];

	[string addAttribute:NSFontAttributeName
								 value:[self.textFont fontWithSize:self.titleLabel.font.pointSize - 2.0f]
								 range:NSMakeRange(sumValuesString.length + 1, self.metricText.length)];

	return string;
}

@end