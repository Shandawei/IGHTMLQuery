//
//  IGHTMLQueryTests.m
//  IGHTMLQueryTests
//
//  Created by Francis Chong on 20/8/13.
//  Copyright (c) 2013 Ignition Soft. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "IGHTMLQuery.h"

@interface IGXMLDocumentTests : XCTestCase {
    IGXMLDocument* doc;
}

@end

@implementation IGXMLDocumentTests

- (void)setUp
{
    [super setUp];
    
    NSString* content = [[NSString alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"catalog" ofType:@"xml"] encoding:NSUTF8StringEncoding error:nil];
    doc = [[IGXMLDocument alloc] initWithXMLString:content error:nil];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testTagAndText {
    IGXMLDocument* hello = [[IGXMLDocument alloc] initWithXMLString:@"<p>Hello</p>" error:nil];
    XCTAssertEqualObjects(hello.tag, @"p");
    XCTAssertEqualObjects(hello.text, @"Hello");
    
    hello.tag = @"span";
    hello.text = @"World";
    XCTAssertEqualObjects(hello.tag, @"span");
    XCTAssertEqualObjects(hello.text, @"World");
    XCTAssertEqualObjects(hello.xml, @"<span>World</span>");
}

- (void)testInnerXmlAndXml {
    IGXMLDocument* myDoc = [[IGXMLDocument alloc] initWithXMLString:@"<?xml version=\"1.0\" ?><catalog><cd country=\"USA\"><title>Empire Burlesque</title><artist>Bob Dylan</artist><price>10.90</price></cd></catalog>" error:nil];
    IGXMLNode* catalog = [myDoc queryWithXPath:@"//catalog"].firstObject;
    XCTAssertEqualObjects(catalog.innerXml, @"<cd country=\"USA\"><title>Empire Burlesque</title><artist>Bob Dylan</artist><price>10.90</price></cd>");
    XCTAssertEqualObjects(catalog.xml, @"<catalog><cd country=\"USA\"><title>Empire Burlesque</title><artist>Bob Dylan</artist><price>10.90</price></cd></catalog>");
}

- (void)testXPath {
    IGXMLNodeSet* cds = [doc queryWithXPath:@"//cd"];
    XCTAssertNotNil(cds);
    XCTAssertTrue(cds.count == 3, @"should have 3 cd");
    
    IGXMLNodeSet* usaCds = [doc queryWithXPath:@"//cd[@country='USA']"];
    XCTAssertNotNil(usaCds);
    XCTAssertTrue(usaCds.count == 2, @"should have 2 cd from USA");
    
    IGXMLNodeSet* ukCds = [doc queryWithXPath:@"//cd[@country='UK']"];
    XCTAssertNotNil(ukCds);
    XCTAssertTrue(ukCds.count == 1, @"should have 1 cd from UK");
}

- (void)testXPathOnChild {
    IGXMLNodeSet* usaCds = [doc queryWithXPath:@"//cd[@country='USA']"];
    IGXMLNode* price = [[usaCds[0] queryWithXPath:@"price"] firstObject];
    XCTAssertEqualObjects(price.text, @"10.90");
}

- (void)testXPathShorthand {
    IGXMLNodeSet* cds = [doc queryWithXPath:@"//cd"];
    XCTAssertNotNil(cds);
    XCTAssertTrue(cds.count == 3, @"should have 3 cd");

}

- (void)testParseError {
    NSError* error = nil;
    doc = [[IGXMLDocument alloc] initWithXMLString:@"Hi" error:&error];
    XCTAssertNil(doc);
    XCTAssertNotNil(error);
    
    error = nil;
    doc = [[IGXMLDocument alloc] initWithXMLString:@"<xml></xml>" error:&error];
    XCTAssertNotNil(doc);
    XCTAssertNil(error);
}

- (void)testRemove {
    [[doc queryWithXPath:@"//cd"] enumerateNodesUsingBlock:^(IGXMLNode *cd, NSUInteger idx, BOOL *stop) {
        NSString* title = [[[cd queryWithXPath:@"./title"] firstObject] text];
        NSLog(@"cd: %@", title);
        if (![title isEqualToString:@"Empire Burlesque"]) {
            [cd remove];
        }
    }];
    
    IGXMLNodeSet* nodes = [doc queryWithXPath:@"//cd"];
    XCTAssertTrue(nodes.count == 1, @"should have 1 node");
    XCTAssertEqualObjects([nodes queryWithXPath:@"title"].firstObject.text, @"Empire Burlesque");
    
}

- (void)testEmpty {
    [[doc queryWithXPath:@"//cd"] enumerateNodesUsingBlock:^(IGXMLNode *cd, NSUInteger idx, BOOL *stop) {
        NSString* title = [[[cd queryWithXPath:@"./title"] firstObject] text];
        NSLog(@"cd: %@", title);
        if ([title isEqualToString:@"Empire Burlesque"]) {
            [cd empty];
        }
    }];
    
    [[doc queryWithXPath:@"//cd"] enumerateNodesUsingBlock:^(IGXMLNode *cd, NSUInteger idx, BOOL *stop) {
        NSString* title = [[[cd queryWithXPath:@"./title"] firstObject] text];
        NSLog(@"cd: %@", title);
        if ([title isEqualToString:@"Empire Burlesque"]) {
            [cd empty];
        }
    }];

    IGXMLNodeSet* nodes = [doc queryWithXPath:@"//cd"];
    XCTAssertTrue(nodes.count == 3, @"should have 3 node");
    XCTAssertEqualObjects([nodes[0] innerXml], @"");
    XCTAssertEqualObjects([doc queryWithXPath:@"//cd[@country='USA']//title"].firstObject.text, @"Greatest Hits");
    XCTAssertEqualObjects([doc queryWithXPath:@"//cd[@country='UK']//title"].firstObject.text, @"Hide your heart");
}

- (void)testAppend {
    [[doc queryWithXPath:@"//cd/title"] enumerateNodesUsingBlock:^(IGXMLNode *cd, NSUInteger idx, BOOL *stop) {
        [cd appendWithXMLString:@"<test/>"];
    }];
    XCTAssertEqualObjects([doc queryWithXPath:@"//cd/title"].firstObject.innerXml, @"Empire Burlesque<test/>");
}

- (void)testAppend2 {
    [[doc queryWithXPath:@"//cd/title"] enumerateNodesUsingBlock:^(IGXMLNode *cd, NSUInteger idx, BOOL *stop) {
        [cd appendWithNode:[[IGXMLDocument alloc] initWithXMLString:@"<test/>" error:nil]];
    }];
    XCTAssertEqualObjects([doc queryWithXPath:@"//cd/title"].firstObject.innerXml, @"Empire Burlesque<test/>");
}

- (void)testPrepend {
    [[doc queryWithXPath:@"//cd/title"] enumerateNodesUsingBlock:^(IGXMLNode *cd, NSUInteger idx, BOOL *stop) {
        [cd prependWithXMLString:@"<test/>"];
    }];
    XCTAssertEqualObjects([doc queryWithXPath:@"//cd/title"].firstObject.innerXml, @"<test/>Empire Burlesque");
}

- (void)testPrepend2 {
    [[doc queryWithXPath:@"//cd/title"] enumerateNodesUsingBlock:^(IGXMLNode *cd, NSUInteger idx, BOOL *stop) {
        [cd prependWithNode:[[IGXMLDocument alloc] initWithXMLString:@"<test/>" error:nil]];
    }];
    XCTAssertEqualObjects([doc queryWithXPath:@"//cd/title"].firstObject.innerXml, @"<test/>Empire Burlesque");
}

- (void)testAddNextSibling {
    doc = [[IGXMLDocument alloc] initWithXMLString:@"<div><h2>Greetings</h2><div class=\"inner\">Hello</div><div class=\"inner\">World</div></div>"  error:nil];
    
    [[doc queryWithXPath:@"//*[@class='inner']"] enumerateNodesUsingBlock:^(IGXMLNode *cd, NSUInteger idx, BOOL *stop) {
        [cd addNextSiblingWithXMLString:@"<p>Test</p>"];
    }];
    
    XCTAssertEqualObjects(doc.innerXml,
                          @"<h2>Greetings</h2><div class=\"inner\">Hello</div><p>Test</p><div class=\"inner\">World</div><p>Test</p>");
}

- (void)testAddNextSibling2 {
    doc = [[IGXMLDocument alloc] initWithXMLString:@"<div><h2>Greetings</h2><div class=\"inner\">Hello</div><div class=\"inner\">World</div></div>"  error:nil];
    
    [[doc queryWithXPath:@"//*[@class='inner']"] enumerateNodesUsingBlock:^(IGXMLNode *cd, NSUInteger idx, BOOL *stop) {
        [cd addNextSiblingWithNode:[[IGXMLDocument alloc] initWithXMLString:@"<p>Test</p>" error:nil]];
    }];

    XCTAssertEqualObjects(doc.innerXml,
                          @"<h2>Greetings</h2><div class=\"inner\">Hello</div><p>Test</p><div class=\"inner\">World</div><p>Test</p>");
}

- (void)testPreviousNextSibling {
    doc = [[IGXMLDocument alloc] initWithXMLString:@"<div><h2>Greetings</h2><div class=\"inner\">Hello</div><div class=\"inner\">World</div></div>" error:nil];
    
    [[doc queryWithXPath:@"//*[@class='inner']"] enumerateNodesUsingBlock:^(IGXMLNode *node, NSUInteger idx, BOOL *stop) {
        [node addPreviousSiblingWithXMLString:@"<p>Test</p>"];
    }];
    
    XCTAssertEqualObjects(doc.innerXml,
                          @"<h2>Greetings</h2><p>Test</p><div class=\"inner\">Hello</div><p>Test</p><div class=\"inner\">World</div>");
}

- (void)testPreviousNextSibling2 {
    doc = [[IGXMLDocument alloc] initWithXMLString:@"<div><h2>Greetings</h2><div class=\"inner\">Hello</div><div class=\"inner\">World</div></div>"  error:nil];
    
    [[doc queryWithXPath:@"//*[@class='inner']"] enumerateNodesUsingBlock:^(IGXMLNode *cd, NSUInteger idx, BOOL *stop) {
        [cd addPreviousSiblingWithNode:[[IGXMLDocument alloc] initWithXMLString:@"<p>Test</p>" error:nil]];
    }];
    
    XCTAssertEqualObjects(doc.innerXml,
                          @"<h2>Greetings</h2><p>Test</p><div class=\"inner\">Hello</div><p>Test</p><div class=\"inner\">World</div>");
}

//- (void)testNamespaces {
//    NSError* error = nil;
//    
//    NSString* content = [[NSString alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"atom" ofType:@"xml"] encoding:NSUTF8StringEncoding error:nil];
//    IGXMLDocument* atom = [[IGHTMLDocument alloc] initWithHTMLString:content error:nil];
//    [atom removeNamespaces];
//    
//    IGXMLNode* entry = [atom queryWithXPath:@"//entry"].firstObject;
//    XCTAssertNotNil(entry);
//    
//    IGXMLNodeSet* titles = [atom queryWithCSS:@"title"];
//    NSString* lang = titles.firstObject[@"lang"];
//    XCTAssertEqualObjects(lang, @"zh-Hant");
//}

- (void)testIsEuqal {
    IGXMLNode* node1a = [doc queryWithXPath:@"cd"].firstObject;
    IGXMLNode* node1b = [doc queryWithXPath:@"cd"].firstObject;
    IGXMLNode* node2 = [doc queryWithXPath:@"cd"][1];

    XCTAssertTrue([node1a isEqual:node1b]);
    XCTAssertTrue([node1b isEqual:node1a]);
    XCTAssertEqualObjects(node1a.uniqueKey, node1b.uniqueKey);

    XCTAssertFalse([node1a isEqual:node2]);
    XCTAssertNotEqualObjects(node1a.uniqueKey, node2.uniqueKey);
}

- (void)testCopyNode {
    IGXMLNode* node1a;
    IGXMLNode* node1b;
    
    // get a copy of the node.
    node1a = [[doc queryWithXPath:@"cd"].firstObject copy];
    node1b = [node1a copy];

    // if we just use the object return by query (instead of a copy of it),
    // when we dereference the doc, try to access the node will crash the app
    doc = nil;

    XCTAssertEqualObjects([node1a xml], [node1b xml]);
}

- (void)testCopyDoc {
    IGXMLDocument* docCopy1;
    IGXMLDocument* docCopy2;
    
    // get copies of the doc.
    docCopy1 = [doc copy];
    docCopy2 = [docCopy1 copy];
    doc = nil;
    
    XCTAssertEqualObjects([docCopy1 xml], [docCopy2 xml]);
}

- (void) testQuerySameNode {
    doc = [[IGHTMLDocument alloc] initWithHTMLString:@"<html><body><ul><li>1</li><li>1</li><li>2</li></ul>" error:nil];
    XCTAssertNotNil(doc);
    
    XCTAssertEqual(3U, [[doc queryWithXPath:@"//li"] count]);
    
    [[doc queryWithXPath:@"//li"] enumerateNodesUsingBlock:^(IGXMLNode *elem, NSUInteger idx, BOOL *stop) {
        [elem remove];
    }];
    
    XCTAssertEqual(0U, [[doc queryWithXPath:@"//li"] count]);
    
}

- (void)testQuery
{
    IGXMLNodeSet* cds1 = [doc query:@"//cd"];
    IGXMLNodeSet* cds2 = [doc query:@"cd"];
    XCTAssertEqual([cds1 count], 3U, @"should query with XPath");
    XCTAssertEqual([cds2 count], 3U, @"should query with CSS");
}

@end
