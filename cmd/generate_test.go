package cmd

import (
	"path/filepath"
	"testing"
)

func BenchmarkGenerateCommandExecution(b *testing.B) {
	cmd := NewGenerateCmd()
	for i := 0; i < b.N; i++ {
		err := cmd.RunE(nil, []string{filepath.Join("..", "testdata", "values.yaml")})
		if err != nil {
			b.Fatal(err)
		}
	}
}
