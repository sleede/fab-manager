/**
 * This function wraps a Promise to make it compatible with react Suspense
 */
export interface IWrapPromise<T> {
  read: () => T
}

function wrapPromise(promise: Promise<any>): IWrapPromise<any> {
  let status: string = 'pending';
  let response: any;

  const suspender: Promise<any> = promise.then(
    (res) => {
      status = 'success'
      response = res
    },
    (err) => {
      status = 'error'
      response = err
    },
  );

  const read = (): any => {
    switch (status) {
      case 'pending':
        throw suspender
      case 'error':
        throw response
      default:
        return response
    }
  };

  return { read };
}

export default wrapPromise;
