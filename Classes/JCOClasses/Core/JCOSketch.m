
#import "JCOSketch.h"

#define kAnimationKey @"transitionViewAnimation"

#define UIColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@implementation JCOSketch

@synthesize lines, undoHistory, undoto;

- (id)init 
{
	if (self == [super init]) 
	{
		self.lines = [NSMutableArray arrayWithCapacity:1];
		self.undoHistory = [NSMutableArray arrayWithCapacity:1];
		self.undoto = 0;
	}
	return self;
}

- (id) initWithJson:(NSDictionary *)dictionary
{
	[self init];
	NSArray *lineArray = [dictionary objectForKey:@"lines"];
	NSString *colorRGB = [dictionary objectForKey:@"color"]; // format: rrggbb in HEX
	
	if (colorRGB)
	{
		NSScanner *theScanner = [NSScanner scannerWithString:colorRGB];
		uint colorVal;
		[theScanner scanHexInt:&colorVal];
	}

	// Scan for "x,y" - need to ignore the comma,
	NSCharacterSet *commaSet = [NSCharacterSet characterSetWithCharactersInString:@","];
	
	for (NSArray *line in lineArray) 
	{
		JCOLine * lineVal = [[JCOLine alloc]init];
		for (NSString *pointPair in line)
		{
			NSScanner *theScanner = [NSScanner scannerWithString:pointPair];
			[theScanner setCharactersToBeSkipped:commaSet];
			NSInteger x, y;
			[theScanner scanInteger:&x];
			[theScanner scanInteger:&y];
			CGPoint point = CGPointMake(x, y);
			[lineVal addPoint:point];
		}
		[lines addObject:lineVal];
		[lineVal release];
	}
	return self;
}

- (void) startLineAt:(CGPoint)point
{
	JCOLine * line = [[JCOLine alloc]init];
	[lines addObject:line];
	[line release];
	[self addPoint:point];
}

- (void) addPoint:(CGPoint)point
{
	JCOLine *currentLine = [lines lastObject];
	[currentLine addPoint:point];
}

- (void)visitPoints:(id <PointVisitor>)visitor
{
    for (JCOLine *line in self.lines)
    {
        [line.color setStroke];
        NSMutableArray *points = line.points;
        NSValue *firstValue = [points objectAtIndex:0];
        CGPoint firstPoint = [firstValue CGPointValue];
        [visitor visitLineAt:firstPoint];

        if ([points count] > 1) // don't draw single points.
        {

            for (NSValue *val in points)
            {
                CGPoint point = [val CGPointValue];
                [visitor visitPoint:point];
            }
        }

    }
}


// removes just the lines and the undoHistory.
-(void) clear 
{
	[lines removeAllObjects];
	[undoHistory removeAllObjects];
}

- (void) undo {
	JCOLine *lastLine = [lines lastObject];
	if (!lastLine) return;
	// check undoto
	if (undoto >= [lines count]) return;
	
	[undoHistory addObject:lastLine];
	[lines removeLastObject];

}

- (void) redo {
	if (![undoHistory lastObject]) return;
	[lines addObject:[undoHistory lastObject]];
	[undoHistory removeLastObject];
}

- (void) dealloc
{
	[lines release];
	[undoHistory release];
	[super dealloc];
}

@end
