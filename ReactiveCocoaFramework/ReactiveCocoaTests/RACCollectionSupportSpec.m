//
//  RACCollectionSupportSpec.m
//  ReactiveCocoa
//
//  Created by Justin Spahr-Summers on 2012-11-01.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "NSArray+RACSupport.h"
#import "NSDictionary+RACSupport.h"
#import "NSHashTable+RACSupport.h"
#import "NSMapTable+RACSupport.h"
#import "NSOrderedSet+RACSupport.h"
#import "NSSet+RACSupport.h"
#import "NSString+RACSupport.h"
#import "RACSignal+Operations.h"
#import "RACTuple.h"

SpecBegin(RACCollectionSupport)

__block NSArray *numbers;

beforeEach(^{
	NSMutableArray *mutableNumbers = [NSMutableArray array];
	for (NSUInteger i = 0; i < 100; i++) {
		[mutableNumbers addObject:@(i)];
	}

	numbers = [mutableNumbers copy];
});

describe(@"NSArray signals", ^{
	__block NSMutableArray *values;
	__block RACSignal *signal;
	
	beforeEach(^{
		values = [numbers mutableCopy];
		signal = values.rac_signal;
		expect(signal).notTo.beNil();
	});

	it(@"should be immutable", ^{
		NSArray *unchangedValues = [values copy];
		expect([signal array]).to.equal(unchangedValues);

		[values addObject:@6];
		expect([signal array]).to.equal(unchangedValues);
	});
});

describe(@"NSDictionary signals", ^{
	__block NSMutableDictionary *dict;

	__block NSMutableArray *tuples;
	__block RACSignal *tupleSignal;

	__block NSArray *keys;
	__block RACSignal *keySignal;

	__block NSArray *values;
	__block RACSignal *valueSignal;

	beforeEach(^{
		dict = [@{
			@"foo": @"bar",
			@"baz": @"buzz",
			@5: NSNull.null
		} mutableCopy];

		tuples = [NSMutableArray array];
		for (id key in dict) {
			RACTuple *tuple = [RACTuple tupleWithObjects:key, dict[key], nil];
			[tuples addObject:tuple];
		}

		tupleSignal = dict.rac_signal;
		expect(tupleSignal).notTo.beNil();

		keys = [dict.allKeys copy];
		keySignal = dict.rac_keySignal;
		expect(keySignal).notTo.beNil();

		values = [dict.allValues copy];
		valueSignal = dict.rac_valueSignal;
		expect(valueSignal).notTo.beNil();
	});

	it(@"should be immutable", ^{
		expect([tupleSignal array]).to.equal(tuples);
		expect([keySignal array]).to.equal(keys);
		expect([valueSignal array]).to.equal(values);

		dict[@"foo"] = @"rab";
		dict[@6] = @7;

		expect([tupleSignal array]).to.equal(tuples);
		expect([keySignal array]).to.equal(keys);
		expect([valueSignal array]).to.equal(values);
	});
});

describe(@"NSHashTable signals", ^{
	__block NSHashTable *values;
	__block RACSignal *signal;

	beforeEach(^{
		values = [NSHashTable weakObjectsHashTable];
		for (NSNumber *number in numbers) {
			[values addObject:number];
		}
		signal = values.rac_signal;
		expect(signal).notTo.beNil();
	});

	it(@"should be immutable", ^{
		// The signal values' (fast enumeration) order and -allObjects values'
		// order are not the same, so compares equality using set.

		NSSet *unchangedValues = [NSSet setWithArray:[values.allObjects copy]];
		expect([NSSet setWithArray:[signal array]]).to.equal(unchangedValues);

		[values addObject:@6];
		expect([NSSet setWithArray:[signal array]]).to.equal(unchangedValues);
	});

	it(@"should not retain the objects in the collection by itself", ^{
		NSUInteger count = values.allObjects.count;

		@autoreleasepool {
			NSObject *obj __attribute__((objc_precise_lifetime)) = [NSObject new];
			[values addObject:obj];

			signal = values.rac_signal;
		}

		expect([signal array].count).to.equal(count);
	});
});

describe(@"NSMapTable signals", ^{
	__block NSMapTable *mapTable;

	__block NSMutableArray *tuples;
	__block RACSignal *tupleSignal;

	__block NSArray *keys;
	__block RACSignal *keySignal;

	__block NSArray *values;
	__block RACSignal *valueSignal;

	beforeEach(^{
		mapTable = [NSMapTable weakToWeakObjectsMapTable];
		[mapTable setObject:@"bar" forKey:@"foo"];
		[mapTable setObject:@"buzz" forKey:@"baz"];
		[mapTable setObject:NSNull.null forKey:@5];

		tuples = [NSMutableArray array];
		for (id key in mapTable) {
			RACTuple *tuple = [RACTuple tupleWithObjects:key, [mapTable objectForKey:key], nil];
			[tuples addObject:tuple];
		}

		tupleSignal = mapTable.rac_signal;
		expect(tupleSignal).notTo.beNil();

		keys = [mapTable.keyEnumerator.allObjects copy];
		keySignal = mapTable.rac_keySignal;
		expect(keySignal).notTo.beNil();

		values = [mapTable.objectEnumerator.allObjects copy];
		valueSignal = mapTable.rac_valueSignal;
		expect(valueSignal).notTo.beNil();
	});

	it(@"should be immutable", ^{
		expect([tupleSignal array]).to.equal(tuples);
		expect([keySignal array]).to.equal(keys);
		expect([valueSignal array]).to.equal(values);

		[mapTable setObject:@"rab" forKey:@"foo"];
		[mapTable setObject:@7 forKey:@6];

		expect([tupleSignal array]).to.equal(tuples);
		expect([keySignal array]).to.equal(keys);
		expect([valueSignal array]).to.equal(values);
	});

	it(@"should not retain the keys and values in the collection by itself", ^{
		@autoreleasepool {
			NSObject *key __attribute__((objc_precise_lifetime)) = [NSObject new];
			NSObject *value __attribute__((objc_precise_lifetime)) = [NSObject new];
			[mapTable setObject:value forKey:key];

			tupleSignal = mapTable.rac_signal;
			keySignal = mapTable.rac_keySignal;
			valueSignal = mapTable.rac_valueSignal;
		}

		expect([tupleSignal array]).to.equal(tuples);
		expect([keySignal array]).to.equal(keys);
		expect([valueSignal array]).to.equal(values);
	});
});

describe(@"NSOrderedSet signals", ^{
	__block NSMutableOrderedSet *values;
	__block RACSignal *signal;

	beforeEach(^{
		values = [NSMutableOrderedSet orderedSetWithArray:numbers];
		signal = values.rac_signal;
		expect(signal).notTo.beNil();
	});

	it(@"should be immutable", ^{
		NSArray *unchangedValues = [values.array copy];
		expect([signal array]).to.equal(unchangedValues);

		[values addObject:@6];
		expect([signal array]).to.equal(unchangedValues);
	});
});

describe(@"NSSet signals", ^{
	__block NSMutableSet *values;
	__block RACSignal *signal;

	beforeEach(^{
		values = [NSMutableSet setWithArray:numbers];
		signal = values.rac_signal;
		expect(signal).notTo.beNil();
	});

	it(@"should be immutable", ^{
		NSArray *unchangedValues = [values.allObjects copy];
		expect([signal array]).to.equal(unchangedValues);

		[values addObject:@6];
		expect([signal array]).to.equal(unchangedValues);
	});
});

describe(@"NSString signals", ^{
	it(@"should enumerate immutably", ^{
		NSMutableString *string = [@"foo bar" mutableCopy];
		NSArray *values = @[
			RACTuplePack(@"foo", [NSValue valueWithRange:NSMakeRange(0, 3)], [NSValue valueWithRange:NSMakeRange(0, 4)]),
			RACTuplePack(@"bar", [NSValue valueWithRange:NSMakeRange(4, 3)], [NSValue valueWithRange:NSMakeRange(4, 3)]),
		];

		RACSignal *signal = [string rac_substringsInRange:NSMakeRange(0, string.length) options:NSStringEnumerationByWords];
		expect([signal array]).to.equal(values);

		[string appendString:@"buzz"];
		expect([signal array]).to.equal(values);
	});

	it(@"should work with composed characters", ^{
		NSString *string = @"\u2665\uFE0F\u2666\uFE0F";
		RACSignal *signal = [[string
			rac_substringsInRange:NSMakeRange(0, string.length) options:NSStringEnumerationByComposedCharacterSequences]
			reduceEach:^(NSString *substring, NSValue *substringRange, NSValue *enclosingRange) {
				return substring;
			}];

		NSArray *values = @[ @"\u2665\uFE0F", @"\u2666\uFE0F" ];
		expect([signal array]).to.equal(values);
	});
});

describe(@"RACTuple signals", ^{
	__block RACTuple *tuple;
	__block RACSignal *signal;
	
	beforeEach(^{
		tuple = RACTuplePack(@"foo", nil, @"bar", NSNull.null, RACTupleNil.tupleNil);

		signal = tuple.rac_signal;
		expect(signal).notTo.beNil();
	});

	it(@"should match tuple", ^{
		NSArray *values = @[
			@"foo",
			NSNull.null,
			@"bar",
			NSNull.null,
			NSNull.null,
		];

		expect([signal array]).to.equal(values);
	});
});

SpecEnd
