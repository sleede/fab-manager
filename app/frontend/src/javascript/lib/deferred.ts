// This is a kind of promise you can resolve from outside the function callback.
// Credits to https://stackoverflow.com/a/71158892/1039377
export default class Deferred<T> {
  public readonly promise: Promise<T>;
  private resolveFn!: (value: T | PromiseLike<T>) => void;
  private rejectFn!: (reason?: unknown) => void;

  public constructor () {
    this.promise = new Promise<T>((resolve, reject) => {
      this.resolveFn = resolve;
      this.rejectFn = reject;
    });
  }

  public reject (reason?: unknown): void {
    this.rejectFn(reason);
  }

  public resolve (param: T): void {
    this.resolveFn(param);
  }
}
