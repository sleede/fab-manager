<!-- Drop options -->

## [A] Single |> [B] Single
  [A] = index de [B]
  offset && [A] child de [B]

<!--## [A] Single || Child |> [B] Parent
  [A] = index de [B]
  [A] child de [B]-->

<!--## [A] Single || Child |> [B] Child
  [A] = index de [B]
  [A] même parent que [B]-->

## [A] Child |> [B] Single
  [A] = index de [B]
  offset
    ? [A] child de [B]
    : [A] Single

<!--## [A] Parent |> [B] Single
  [A] = index de [B]-->

<!--## [A] Parent |> [B] Parent
  down
    ? [A] = index du dernier child de [B]
    : [A] = index de [B]-->

<!--## [A] Parent |> [B] Child
  down
    ? [A] = index du dernier child de [B]
    : [A] = index du parent de [B]-->

## [A] Single |> [A]
  offset && [A] child du précédant parent