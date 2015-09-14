//===- swift/unittests/runtime/Refcounting.cpp - Reference-counting -------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#include <Foundation/NSObject.h>
#include <objc/runtime.h>
#include "swift/Runtime/HeapObject.h"
#include "swift/Runtime/Metadata.h"
#include "gtest/gtest.h"

using namespace swift;

static unsigned DestroyedObjCCount = 0;
/// A trivial class that increments DestroyedObjCCount when deallocated.
@interface ObjCTestClass : NSObject @end
@implementation ObjCTestClass
- (void) dealloc {
  DestroyedObjCCount++;
  [super dealloc];
}
@end
static HeapObject *make_objc_object() {
  return static_cast<HeapObject *>([ObjCTestClass new]);
}

struct TestObject : HeapObject {
  size_t *Addr;
  size_t Value;
};

static void destroyTestObject(HeapObject *_object) {
  auto object = static_cast<TestObject*>(_object);
  assert(object->Addr && "object already deallocated");
  *object->Addr = object->Value;
  object->Addr = nullptr;
  swift_deallocObject(object, sizeof(TestObject), alignof(TestObject) - 1);
}

static const FullMetadata<ClassMetadata> TestClassObjectMetadata = {
  { { &destroyTestObject }, { &_TWVBo } },
  { { { MetadataKind::Class } }, 0, /*rodata*/ 1,
  ClassFlags::UsesSwift1Refcounting, nullptr, 0, 0, 0, 0, 0 }
};

/// Create an object that, when deallocated, stores the given value to
/// the given pointer.
static TestObject *allocTestObject(size_t *addr, size_t value) {
  auto result =
    static_cast<TestObject *>(swift_allocObject(&TestClassObjectMetadata,
                                                sizeof(TestObject),
                                                alignof(TestObject) - 1));
  result->Addr = addr;
  result->Value = value;
  return result;
}

TEST(RefcountingTest, release) {
  size_t value = 0;
  auto object = allocTestObject(&value, 1);
  EXPECT_EQ(0u, value);
  swift_release(object);
  EXPECT_EQ(1u, value);
}

TEST(RefcountingTest, retain_release) {
  size_t value = 0;
  auto object = allocTestObject(&value, 1);
  EXPECT_EQ(0u, value);
  auto retainResult = swift_retain(object);
  EXPECT_EQ(object, retainResult);
  EXPECT_EQ(0u, value);
  swift_release(object);
  EXPECT_EQ(0u, value);
  swift_release(object);
  EXPECT_EQ(1u, value);
}

TEST(RefcountingTest, pin_unpin) {
  size_t value = 0;
  auto object = allocTestObject(&value, 1);
  EXPECT_EQ(0u, value);
  auto pinResult = swift_tryPin(object);
  EXPECT_EQ(object, pinResult);
  EXPECT_EQ(0u, value);
  swift_release(object);
  EXPECT_EQ(0u, value);
  swift_unpin(object);
  EXPECT_EQ(1u, value);
}

TEST(RefcountingTest, pin_pin_unpin_unpin) {
  size_t value = 0;
  auto object = allocTestObject(&value, 1);
  EXPECT_EQ(0u, value);
  auto pinResult = swift_tryPin(object);
  EXPECT_EQ(object, pinResult);
  EXPECT_EQ(0u, value);
  auto pinResult2 = swift_tryPin(object);
  EXPECT_EQ(nullptr, pinResult2);
  EXPECT_EQ(0u, value);
  swift_unpin(pinResult2);
  EXPECT_EQ(0u, value);
  swift_release(object);
  EXPECT_EQ(0u, value);
  swift_unpin(object);
  EXPECT_EQ(1u, value);
}

TEST(RefcountingTest, retain_release_n) {
  size_t value = 0;
  auto object = allocTestObject(&value, 1);
  EXPECT_EQ(0u, value);
  auto retainResult = swift_retain_n(object, 32);
  EXPECT_EQ(object, retainResult);
  retainResult = swift_retain(object);
  EXPECT_EQ(object, retainResult);
  EXPECT_EQ(0u, value);
  EXPECT_EQ(34u, swift_retainCount(object));
  swift_release_n(object, 31);
  EXPECT_EQ(0u, value);
  EXPECT_EQ(3u, swift_retainCount(object));
  swift_release(object);
  EXPECT_EQ(0u, value);
  EXPECT_EQ(2u, swift_retainCount(object));
  swift_release_n(object, 1);
  EXPECT_EQ(0u, value);
  EXPECT_EQ(1u, swift_retainCount(object));
  swift_release(object);
  EXPECT_EQ(1u, value);
}

TEST(RefcountingTest, unknown_retain_release_n) {
  size_t value = 0;
  auto object = allocTestObject(&value, 1);
  EXPECT_EQ(0u, value);
  auto retainResult = swift_unknownRetain_n(object, 32);
  EXPECT_EQ(object, retainResult);
  retainResult = swift_unknownRetain(object);
  EXPECT_EQ(object, retainResult);
  EXPECT_EQ(0u, value);
  EXPECT_EQ(34u, swift_retainCount(object));
  swift_unknownRelease_n(object, 31);
  EXPECT_EQ(0u, value);
  EXPECT_EQ(3u, swift_retainCount(object));
  swift_unknownRelease(object);
  EXPECT_EQ(0u, value);
  EXPECT_EQ(2u, swift_retainCount(object));
  swift_unknownRelease_n(object, 1);
  EXPECT_EQ(0u, value);
  EXPECT_EQ(1u, swift_retainCount(object));
  swift_unknownRelease(object);
  EXPECT_EQ(1u, value);
}

TEST(RefcountingTest, objc_unknown_retain_release_n) {
  auto object = make_objc_object();
  auto retainResult = swift_unknownRetain_n(object, 32);
  EXPECT_EQ(object, retainResult);
  retainResult = swift_unknownRetain(object);
  EXPECT_EQ(object, retainResult);
  swift_unknownRelease_n(object, 31);
  swift_unknownRelease(object);
  swift_unknownRelease_n(object, 1);
  swift_unknownRelease(object);
  // The object should be destroyed by now.
  EXPECT_EQ(1u, DestroyedObjCCount);
}