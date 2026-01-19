package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestAdd(t *testing.T) {
	assert.Equal(t, 8, add(5, 3))
	assert.Equal(t, 0, add(0, 0))
	assert.Equal(t, -5, add(-2, -3))
}
