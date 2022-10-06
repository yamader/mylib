const interleave = <T>(front: T[], ...queue: T[][]): T[] => {
  const [head, ...tail] = front
  const [next, ...after] = queue
  return !queue.length
    ? front
    : !front.length
      ? interleave(next, ...after)
      : [head, ...interleave(next, ...after, tail)]
}

// test
console.log(interleave([1, 2, 3, 4, 5],
                       [10, 20, 30],
                       [100, 200]))
